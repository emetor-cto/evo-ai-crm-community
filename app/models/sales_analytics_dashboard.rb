# frozen_string_literal: true

class SalesAnalyticsDashboard < ApplicationRecord
  KINDS = %w[conversion commissioning forecast prospecting].freeze

  belongs_to :updated_by, class_name: 'User', optional: true

  validates :kind, presence: true, inclusion: { in: KINDS }
  validates :year, presence: true, numericality: { only_integer: true, greater_than: 2000, less_than: 2100 }
  validates :kind, uniqueness: { scope: :year }

  def self.find_or_initialize_for(kind:, year:)
    find_or_initialize_by(kind: kind, year: year) do |record|
      record.data = SalesAnalytics::Defaults.for(kind)
    end
  end
end
