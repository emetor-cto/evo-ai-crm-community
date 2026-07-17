# frozen_string_literal: true

class DashboardChecklistItem < ApplicationRecord
  belongs_to :dashboard_checklist, inverse_of: :items

  has_many :completions, class_name: 'DashboardChecklistCompletion', dependent: :destroy,
                         inverse_of: :dashboard_checklist_item

  validates :title, presence: true, length: { maximum: 255 }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :ordered, -> { order(:position, :created_at) }

  def completed_today_by?(user_id, date = Date.current)
    completions.exists?(user_id: user_id, completed_on: date)
  end
end
