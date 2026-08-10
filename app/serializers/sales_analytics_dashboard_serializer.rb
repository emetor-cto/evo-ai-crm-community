# frozen_string_literal: true

module SalesAnalyticsDashboardSerializer
  extend self

  def serialize(record, data: nil, live_fields: [])
    {
      id: record.id,
      kind: record.kind,
      year: record.year,
      data: data || record.data || {},
      live_fields: Array(live_fields),
      updated_by_id: record.updated_by_id,
      created_at: record.created_at&.iso8601,
      updated_at: record.updated_at&.iso8601
    }
  end

  def serialize_collection(records)
    Array(records).map { |record| serialize(record) }
  end
end
