# frozen_string_literal: true

module PipelineTaskTemplateSerializer
  extend self

  def serialize(template)
    {
      id: template.id,
      title: template.title,
      description: template.description,
      task_type: template.task_type,
      priority: template.priority,
      due_in_days: template.due_in_days,
      active: template.active,
      position: template.position,
      created_by_id: template.created_by_id,
      created_at: template.created_at&.iso8601,
      updated_at: template.updated_at&.iso8601
    }
  end

  def serialize_collection(templates)
    return [] unless templates

    templates.map { |template| serialize(template) }
  end
end
