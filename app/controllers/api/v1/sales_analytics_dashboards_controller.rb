# frozen_string_literal: true

class Api::V1::SalesAnalyticsDashboardsController < Api::V1::BaseController
  require_permissions({
    show: 'dashboard.read',
    update: 'dashboard.read'
  })

  before_action :validate_kind!
  before_action :authorize_commissioning_admin!
  before_action :fetch_or_build_dashboard

  # GET /api/v1/sales_analytics_dashboards/:kind?year=2026
  def show
    success_response(
      data: serialize_with_live(@dashboard),
      message: 'Sales analytics dashboard retrieved successfully'
    )
  end

  # PUT /api/v1/sales_analytics_dashboards/:kind?year=2026
  def update
    attrs = dashboard_params
    @dashboard.data = sanitize_persisted_data(attrs[:data]) if attrs.key?(:data)
    @dashboard.updated_by = Current.user
    @dashboard.save!

    success_response(
      data: serialize_with_live(@dashboard),
      message: 'Sales analytics dashboard saved successfully'
    )
  rescue ActiveRecord::RecordInvalid => e
    error_response(
      ApiErrorCodes::VALIDATION_ERROR,
      'Validation failed',
      details: e.record.errors.to_hash,
      status: :unprocessable_entity
    )
  end

  private

  def validate_kind!
    return if SalesAnalyticsDashboard::KINDS.include?(params[:kind].to_s)

    error_response(
      ApiErrorCodes::VALIDATION_ERROR,
      'Invalid dashboard kind',
      details: { kind: params[:kind], allowed: SalesAnalyticsDashboard::KINDS },
      status: :unprocessable_entity
    )
  end

  def authorize_commissioning_admin!
    return unless params[:kind].to_s == 'commissioning'
    return if Current.user&.administrator?

    error_response(
      ApiErrorCodes::FORBIDDEN,
      'Only administrators can access the commissioning dashboard',
      status: :forbidden
    )
  end

  def fetch_or_build_dashboard
    year = (params[:year].presence || Time.zone.today.year).to_i
    @dashboard = SalesAnalyticsDashboard.find_or_initialize_for(
      kind: params[:kind],
      year: year
    )
    # Persist empty shell on first read so subsequent clients share the same row.
    if @dashboard.new_record?
      @dashboard.updated_by = Current.user
      @dashboard.save!
    end
  end

  def dashboard_params
    raw = params.require(:sales_analytics_dashboard)
    data = raw[:data]
    data = data.to_unsafe_h if data.is_a?(ActionController::Parameters)
    { data: data || {} }
  end

  def serialize_with_live(record)
    live = SalesAnalytics::LiveMetrics.new(kind: record.kind, year: record.year).call(record.data)
    SalesAnalyticsDashboardSerializer.serialize(
      record,
      data: live[:data],
      live_fields: live[:live_fields]
    )
  end

  # Persist only editable fields; live aggregates are recomputed on every read.
  def sanitize_persisted_data(raw)
    data = deep_stringify(raw || {})
    case params[:kind].to_s
    when 'conversion'
      data.slice('sales_goal_this_year').merge(
        'sales_last_year' => 0,
        'meetings_last_year' => 0,
        'leads_last_year' => 0
      )
    when 'commissioning'
      %w[sdr_people seller_people].each do |key|
        Array(data[key]).each do |person|
          next unless person.is_a?(Hash)

          person['done'] = 0
          person.delete('user_id')
        end
      end
      data
    when 'forecast'
      Array(data['metrics']).each do |metric|
        next unless metric.is_a?(Hash)
        next unless SalesAnalytics::LiveMetrics::LIVE_FORECAST_IDS.include?(metric['id'].to_s)

        Array(metric['months']).each do |pair|
          pair['realizado'] = 0 if pair.is_a?(Hash)
        end
      end
      data
    when 'prospecting'
      {
        'year_goals' => data['year_goals'] || SalesAnalytics::Defaults.for('prospecting')['year_goals'],
        'weeks' => Array.new(52) { SalesAnalytics::Defaults.empty_week },
        'leads' => []
      }
    else
      data
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
