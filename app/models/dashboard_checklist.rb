# frozen_string_literal: true

class DashboardChecklist < ApplicationRecord
  belongs_to :created_by, class_name: 'User'

  has_many :items, class_name: 'DashboardChecklistItem', dependent: :destroy, inverse_of: :dashboard_checklist
  has_many :assignments, class_name: 'DashboardChecklistAssignment', dependent: :destroy, inverse_of: :dashboard_checklist
  has_many :assignees, through: :assignments, source: :user

  validates :title, presence: true, length: { maximum: 255 }

  scope :active, -> { where(active: true) }
  scope :assigned_to_user, lambda { |user_id|
    joins(:assignments).where(dashboard_checklist_assignments: { user_id: user_id })
  }

  accepts_nested_attributes_for :items, allow_destroy: true
end
