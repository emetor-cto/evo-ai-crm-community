# frozen_string_literal: true

module DashboardChecklistSerializer
  module_function

  def serialize(checklist, include_items: true, include_assignees: true)
    data = {
      id: checklist.id,
      title: checklist.title,
      active: checklist.active,
      created_by_id: checklist.created_by_id,
      created_at: checklist.created_at&.iso8601,
      updated_at: checklist.updated_at&.iso8601
    }

    if include_items
      items = checklist.association(:items).loaded? ? checklist.items : checklist.items.ordered
      data[:items] = items.sort_by { |item| [item.position, item.created_at.to_i] }.map { |item| serialize_item(item) }
    end

    if include_assignees
      assignees = checklist.association(:assignees).loaded? ? checklist.assignees : checklist.assignees
      data[:assignee_ids] = assignees.map(&:id)
      data[:assignees] = assignees.map { |user| serialize_user(user) }
    end

    data
  end

  def serialize_collection(checklists)
    checklists.map { |checklist| serialize(checklist) }
  end

  def serialize_item(item, completed: nil)
    payload = {
      id: item.id,
      title: item.title,
      position: item.position,
      dashboard_checklist_id: item.dashboard_checklist_id
    }
    payload[:completed] = completed unless completed.nil?
    payload
  end

  def serialize_user(user)
    {
      id: user.id,
      name: user.try(:available_name) || user.name,
      email: user.email
    }
  end

  def serialize_today(checklists, user_id, date = Date.current)
    checklists.flat_map do |checklist|
      items = checklist.association(:items).loaded? ? checklist.items : checklist.items.ordered
      items.sort_by { |item| [item.position, item.created_at.to_i] }.map do |item|
        serialize_item(item, completed: item.completed_today_by?(user_id, date)).merge(
          checklist_id: checklist.id,
          checklist_title: checklist.title
        )
      end
    end
  end
end
