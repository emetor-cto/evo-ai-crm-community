# frozen_string_literal: true

class Api::V1::DashboardChecklistsController < Api::V1::BaseController
  before_action :ensure_can_manage!, except: [:today, :toggle_item]
  before_action :fetch_checklist, only: [:show, :update, :destroy]

  def index
    checklists = DashboardChecklist.includes(:items, :assignees).order(created_at: :desc)

    success_response(
      data: DashboardChecklistSerializer.serialize_collection(checklists),
      message: 'Dashboard checklists retrieved successfully'
    )
  end

  def show
    success_response(
      data: DashboardChecklistSerializer.serialize(@checklist),
      message: 'Dashboard checklist retrieved successfully'
    )
  end

  def create
    checklist = DashboardChecklist.new(checklist_attributes)
    checklist.created_by = Current.user

    ActiveRecord::Base.transaction do
      checklist.save!
      sync_items!(checklist)
      sync_assignees!(checklist)
    end

    success_response(
      data: DashboardChecklistSerializer.serialize(checklist.reload),
      message: 'Dashboard checklist created successfully',
      status: :created
    )
  rescue ActiveRecord::RecordInvalid => e
    error_response(
      ApiErrorCodes::VALIDATION_ERROR,
      'Validation failed',
      details: format_validation_errors(e.record.errors),
      status: :unprocessable_entity
    )
  end

  def update
    ActiveRecord::Base.transaction do
      @checklist.update!(checklist_attributes)
      sync_items!(@checklist) if params_include_items?
      sync_assignees!(@checklist) if params_include_assignees?
    end

    success_response(
      data: DashboardChecklistSerializer.serialize(@checklist.reload),
      message: 'Dashboard checklist updated successfully'
    )
  rescue ActiveRecord::RecordInvalid => e
    error_response(
      ApiErrorCodes::VALIDATION_ERROR,
      'Validation failed',
      details: format_validation_errors(e.record.errors),
      status: :unprocessable_entity
    )
  end

  def destroy
    deleted_id = @checklist.id
    @checklist.destroy!

    success_response(
      data: { id: deleted_id },
      message: 'Dashboard checklist deleted successfully'
    )
  end

  # GET /api/v1/dashboard_checklists/today
  def today
    date = Date.current
    checklists = DashboardChecklist.active
                                   .assigned_to_user(Current.user.id)
                                   .includes(:items)
                                   .order(:title)

    success_response(
      data: {
        date: date.iso8601,
        items: DashboardChecklistSerializer.serialize_today(checklists, Current.user.id, date)
      },
      message: 'Today dashboard checklist retrieved successfully'
    )
  end

  # POST /api/v1/dashboard_checklists/items/:item_id/toggle
  def toggle_item
    item = DashboardChecklistItem.joins(:dashboard_checklist)
                                 .merge(DashboardChecklist.active.assigned_to_user(Current.user.id))
                                 .find(params[:item_id])

    date = Date.current
    completion = item.completions.find_by(user_id: Current.user.id, completed_on: date)

    if completion
      completion.destroy!
      completed = false
    else
      item.completions.create!(user_id: Current.user.id, completed_on: date)
      completed = true
    end

    success_response(
      data: DashboardChecklistSerializer.serialize_item(item, completed: completed).merge(
        checklist_id: item.dashboard_checklist_id,
        date: date.iso8601
      ),
      message: completed ? 'Item marked as completed' : 'Item marked as pending'
    )
  rescue ActiveRecord::RecordNotFound
    error_response(
      ApiErrorCodes::RESOURCE_NOT_FOUND,
      'Checklist item not found',
      status: :not_found
    )
  end

  private

  def fetch_checklist
    @checklist = DashboardChecklist.includes(:items, :assignees).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    error_response(ApiErrorCodes::RESOURCE_NOT_FOUND, 'Dashboard checklist not found', status: :not_found)
  end

  def ensure_can_manage!
    return if Current.user&.administrator?
    return if Current.user&.respond_to?(:has_permission?) && Current.user.has_permission?('users.manage')

    error_response(
      ApiErrorCodes::FORBIDDEN,
      'You are not allowed to manage dashboard checklists',
      status: :forbidden
    )
  end

  def checklist_attributes
    attrs = {}
    attrs[:title] = permitted_params[:title] if permitted_params.key?(:title)
    attrs[:active] = ActiveModel::Type::Boolean.new.cast(permitted_params[:active]) if permitted_params.key?(:active)
    attrs
  end

  def permitted_params
    params.require(:dashboard_checklist).permit(
      :title,
      :active,
      assignee_ids: [],
      items: [:id, :title, :position, :_destroy]
    )
  end

  def params_include_items?
    permitted_params.key?(:items)
  end

  def params_include_assignees?
    permitted_params.key?(:assignee_ids)
  end

  def sync_items!(checklist)
    incoming = Array(permitted_params[:items])
    keep_ids = []

    incoming.each_with_index do |item_params, index|
      next if ActiveModel::Type::Boolean.new.cast(item_params[:_destroy])

      title = item_params[:title].to_s.strip
      next if title.blank?

      position = item_params[:position].presence || index
      if item_params[:id].present?
        item = checklist.items.find(item_params[:id])
        item.update!(title: title, position: position)
        keep_ids << item.id
      else
        item = checklist.items.create!(title: title, position: position)
        keep_ids << item.id
      end
    end

    checklist.items.where.not(id: keep_ids).destroy_all if params_include_items?
  end

  def sync_assignees!(checklist)
    assignee_ids = Array(permitted_params[:assignee_ids]).map(&:presence).compact.uniq
    checklist.assignments.where.not(user_id: assignee_ids).destroy_all

    assignee_ids.each do |user_id|
      checklist.assignments.find_or_create_by!(user_id: user_id)
    end
  end
end
