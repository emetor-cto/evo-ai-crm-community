# frozen_string_literal: true

module SalesAnalytics
  module Defaults
    module_function

    MONTHS = (1..12).freeze

    def for(kind)
      case kind.to_s
      when 'conversion'
        {
          'sales_last_year' => 0,
          'meetings_last_year' => 0,
          'leads_last_year' => 0,
          'sales_goal_this_year' => 0
        }
      when 'commissioning'
        {
          'seller_ote' => empty_ote_rows('Vendedor'),
          'sdr_ote' => empty_ote_rows('SDR'),
          'coordinator_ote' => empty_ote_rows('Coord.'),
          'sdr_people' => [],
          'seller_people' => []
        }
      when 'forecast'
        {
          'metrics' => forecast_metrics
        }
      when 'prospecting'
        {
          'year_goals' => {
            'connections' => 0,
            'meetings' => 0,
            'opportunities' => 0,
            'wins' => 0
          },
          'weeks' => Array.new(52) { empty_week }
        }
      else
        {}
      end
    end

    def empty_ote_rows(prefix)
      %w[Júnior Pleno Sênior].map do |level|
        {
          'role' => "#{prefix} #{level}",
          'fixed' => 0,
          'variable' => 0
        }
      end
    end

    def empty_week
      {
        'connections' => 0,
        'meetings' => 0,
        'opportunities' => 0,
        'wins' => 0
      }
    end

    def empty_months
      MONTHS.map { |_m| { 'meta' => 0, 'realizado' => 0 } }
    end

    def forecast_metrics
      [
        { 'id' => 'visitors', 'label' => 'Visitantes', 'kind' => 'count', 'months' => empty_months },
        { 'id' => 'lead_rate', 'label' => '% conversão p/ lead', 'kind' => 'rate', 'computed' => 'lead_rate', 'months' => empty_months },
        { 'id' => 'leads', 'label' => 'Número de leads', 'kind' => 'count', 'months' => empty_months },
        { 'id' => 'opp_rate', 'label' => '% conversão p/ oportunidade', 'kind' => 'rate', 'computed' => 'opp_rate', 'months' => empty_months },
        { 'id' => 'opps', 'label' => 'Oportunidades', 'kind' => 'count', 'months' => empty_months },
        { 'id' => 'sale_rate', 'label' => '% conversão p/ venda', 'kind' => 'rate', 'computed' => 'sale_rate', 'months' => empty_months },
        { 'id' => 'sales', 'label' => 'Vendas', 'kind' => 'count', 'months' => empty_months },
        { 'id' => 'leads_email', 'label' => 'Leads via e-mail', 'kind' => 'count', 'months' => empty_months },
        { 'id' => 'leads_organic', 'label' => 'Leads via busca orgânica', 'kind' => 'count', 'months' => empty_months },
        { 'id' => 'leads_social', 'label' => 'Leads via redes sociais', 'kind' => 'count', 'months' => empty_months },
        { 'id' => 'leads_paid', 'label' => 'Leads via mídia paga', 'kind' => 'count', 'months' => empty_months },
        { 'id' => 'paid_budget', 'label' => 'Orçamento de mídia paga (R$)', 'kind' => 'money', 'months' => empty_months },
        { 'id' => 'cpl', 'label' => 'Custo por lead (mídia paga)', 'kind' => 'money', 'computed' => 'cpl', 'months' => empty_months }
      ]
    end
  end
end
