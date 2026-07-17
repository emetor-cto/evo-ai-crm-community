# frozen_string_literal: true

class DashboardChecklistCompletion < ApplicationRecord
  belongs_to :dashboard_checklist_item, inverse_of: :completions
  belongs_to :user

  validates :user_id, presence: true
  validates :completed_on, presence: true
  validates :dashboard_checklist_item_id, uniqueness: { scope: [:user_id, :completed_on] }
end
