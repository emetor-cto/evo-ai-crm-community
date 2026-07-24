# frozen_string_literal: true

# == Schema Information
#
# Table name: pipeline_task_templates
#
#  id            :uuid             not null, primary key
#  title         :string(255)      not null
#  description   :text
#  task_type     :integer          default(0), not null
#  priority      :integer          default(1), not null
#  due_in_days   :integer
#  active        :boolean          default(true), not null
#  created_by_id :uuid             not null
#  position      :integer          default(0), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class PipelineTaskTemplate < ApplicationRecord
  belongs_to :created_by, class_name: 'User'

  enum :task_type, {
    call: 0,
    email: 1,
    meeting: 2,
    follow_up: 3,
    note: 4,
    other: 5
  }, prefix: true

  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    urgent: 3
  }, prefix: true

  validates :title, presence: true, length: { maximum: 255 }
  validates :created_by_id, presence: true
  validates :due_in_days, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :title) }

  def build_task_attrs
    attrs = {
      title: title,
      description: description,
      task_type: task_type,
      priority: priority
    }

    if due_in_days.present?
      attrs[:due_date] = due_in_days.days.from_now.beginning_of_day.iso8601
    end

    attrs
  end
end
