# frozen_string_literal: true

class DashboardChecklistAssignment < ApplicationRecord
  belongs_to :dashboard_checklist, inverse_of: :assignments
  belongs_to :user

  validates :user_id, presence: true, uniqueness: { scope: :dashboard_checklist_id }
end
