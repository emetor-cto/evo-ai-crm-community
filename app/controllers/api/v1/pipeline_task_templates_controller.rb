# frozen_string_literal: true

class Api::V1::PipelineTaskTemplatesController < Api::V1::BaseController
  before_action :fetch_template, only: %i[show update destroy]

  def index
    templates = PipelineTaskTemplate.ordered
    templates = templates.active if ActiveModel::Type::Boolean.new.cast(params[:active])

    success_response(
      data: PipelineTaskTemplateSerializer.serialize_collection(templates),
      message: 'Pipeline task templates retrieved successfully'
    )
  end

  def show
    success_response(
      data: PipelineTaskTemplateSerializer.serialize(@template),
      message: 'Pipeline task template retrieved successfully'
    )
  end

  def create
    @template = PipelineTaskTemplate.new(template_params)
    @template.created_by_id = current_user.id
    @template.position = next_position if @template.position.blank? || @template.position.zero?

    if @template.save
      success_response(
        data: PipelineTaskTemplateSerializer.serialize(@template),
        message: 'Pipeline task template created successfully',
        status: :created
      )
    else
      error_response(
        ApiErrorCodes::VALIDATION_ERROR,
        'Validation failed',
        details: @template.errors.full_messages,
        status: :unprocessable_entity
      )
    end
  end

  def update
    if @template.update(template_params)
      success_response(
        data: PipelineTaskTemplateSerializer.serialize(@template),
        message: 'Pipeline task template updated successfully'
      )
    else
      error_response(
        ApiErrorCodes::VALIDATION_ERROR,
        'Validation failed',
        details: @template.errors.full_messages,
        status: :unprocessable_entity
      )
    end
  end

  def destroy
    @template.destroy!
    success_response(
      data: { id: @template.id },
      message: 'Pipeline task template deleted successfully'
    )
  end

  private

  def fetch_template
    @template = PipelineTaskTemplate.find(params[:id])
  end

  def template_params
    params.require(:pipeline_task_template).permit(
      :title, :description, :task_type, :priority, :due_in_days, :active, :position
    )
  end

  def next_position
    (PipelineTaskTemplate.maximum(:position) || -1) + 1
  end
end
