# frozen_string_literal: true

module SalesAnalytics
  # Merges live CRM aggregates into saved dashboard JSON.
  # Metas/OTE/goals stay from the stored record; "realizado"/done come from the system.
  class LiveMetrics
    LIVE_FORECAST_IDS = %w[leads opps sales].freeze

    def initialize(kind:, year:)
      @kind = kind.to_s
      @year = year.to_i
    end

    def call(saved_data)
      data = deep_stringify(saved_data || {})
      case @kind
      when 'conversion'
        merge_conversion(data)
      when 'commissioning'
        merge_commissioning(data)
      when 'forecast'
        merge_forecast(data)
      when 'prospecting'
        merge_prospecting(data)
      else
        { data: data, live_fields: [] }
      end
    end

    private

    def merge_conversion(data)
      prev = @year - 1
      range = year_range(prev)
      data['sales_last_year'] = sales_count(range)
      data['meetings_last_year'] = meetings_count(range)
      data['leads_last_year'] = leads_count(range)
      {
        data: data,
        live_fields: %w[sales_last_year meetings_last_year leads_last_year]
      }
    end

    def merge_commissioning(data)
      range = year_range(@year)
      users = User.all.to_a
      data['sdr_people'] = Array(data['sdr_people']).map do |person|
        row = person.is_a?(Hash) ? person.dup : {}
        user = match_user(users, row['name'])
        row['done'] = user ? meetings_count(range, assigned_to_id: user.id) : row['done'].to_i
        row['user_id'] = user&.id
        row
      end
      data['seller_people'] = Array(data['seller_people']).map do |person|
        row = person.is_a?(Hash) ? person.dup : {}
        user = match_user(users, row['name'])
        row['done'] = user ? sales_count(range, assigned_by_id: user.id) : row['done'].to_i
        row['user_id'] = user&.id
        row
      end
      {
        data: data,
        live_fields: %w[sdr_people.done seller_people.done]
      }
    end

    def merge_forecast(data)
      metrics = Array(data['metrics']).map do |metric|
        row = metric.is_a?(Hash) ? metric.deep_dup : {}
        next row unless LIVE_FORECAST_IDS.include?(row['id'].to_s)

        months = Array(row['months'])
        months = SalesAnalytics::Defaults.empty_months if months.size != 12
        row['months'] = (0...12).map do |idx|
          pair = months[idx].is_a?(Hash) ? months[idx].dup : { 'meta' => 0, 'realizado' => 0 }
          range = month_range(@year, idx + 1)
          pair['realizado'] = case row['id']
                              when 'leads' then leads_count(range)
                              when 'opps' then opportunities_count(range)
                              when 'sales' then sales_count(range)
                              else pair['realizado'].to_i
                              end
          pair
        end
        row
      end
      data['metrics'] = metrics
      {
        data: data,
        live_fields: LIVE_FORECAST_IDS.map { |id| "metrics.#{id}.realizado" }
      }
    end

    def merge_prospecting(data)
      data.delete('leads')
      data['weeks'] = (1..52).map do |week|
        range = week_range(@year, week)
        {
          'connections' => leads_count(range),
          'meetings' => meetings_count(range),
          'opportunities' => opportunities_count(range),
          'wins' => sales_count(range)
        }
      end
      {
        data: data,
        live_fields: %w[weeks.connections weeks.meetings weeks.opportunities weeks.wins]
      }
    end

    def year_range(year)
      Time.zone.local(year).beginning_of_year..Time.zone.local(year).end_of_year
    end

    def month_range(year, month)
      Time.zone.local(year, month).all_month
    end

    def week_range(year, week)
      start_date = Date.commercial(year, week, 1)
      start_date.beginning_of_day..start_date.end_of_week.end_of_day
    rescue Date::Error, ArgumentError
      # ISO week may not exist for this year (e.g. week 53).
      Time.zone.local(year, 1, 1)..Time.zone.local(year, 1, 1)
    end

    def leads_count(range)
      Contact.where(created_at: range).count
    end

    def opportunities_count(range)
      PipelineItem.where(
        'COALESCE(entered_at, created_at) BETWEEN ? AND ?',
        range.begin,
        range.end
      ).count
    end

    def sales_count(range, assigned_by_id: nil)
      scope = PipelineItem.completed.where(completed_at: range)
      scope = scope.where(assigned_by_id: assigned_by_id) if assigned_by_id
      scope.count
    end

    def meetings_count(range, assigned_to_id: nil)
      scope = PipelineTask.task_type_meeting.status_completed.where(completed_at: range)
      scope = scope.where(assigned_to_id: assigned_to_id) if assigned_to_id
      scope.count
    end

    def match_user(users, name)
      key = name.to_s.downcase.strip
      return nil if key.blank?

      users.find do |user|
        [user.name, user.display_name, user.available_name, user.email]
          .compact
          .map { |v| v.to_s.downcase.strip }
          .include?(key)
      end
    end

    def deep_stringify(value)
      case value
      when Hash
        value.each_with_object({}) { |(k, v), acc| acc[k.to_s] = deep_stringify(v) }
      when Array
        value.map { |item| deep_stringify(item) }
      else
        value
      end
    end
  end
end
