# frozen_string_literal: true

class Api::V1::TeamFoldersController < Api::V1::BaseController
  require_permissions({
                        index: 'team_notes.read',
                        show: 'team_notes.read',
                        create: 'team_notes.create',
                        update: 'team_notes.update',
                        destroy: 'team_notes.delete'
                      })

  before_action :fetch_folder, only: %i[show update destroy]

  def index
    if ActiveModel::Type::Boolean.new.cast(params[:tree])
      success_response(
        data: TeamFolderSerializer.serialize_tree,
        message: 'Team folders retrieved successfully'
      )
    else
      folders = TeamFolder.ordered
      folders = folders.where(parent_id: params[:parent_id].presence) if params.key?(:parent_id)

      success_response(
        data: TeamFolderSerializer.serialize_collection(folders),
        message: 'Team folders retrieved successfully'
      )
    end
  end

  def show
    success_response(
      data: TeamFolderSerializer.serialize(@folder),
      message: 'Team folder retrieved successfully'
    )
  end

  def create
    @folder = TeamFolder.new(folder_params)
    @folder.created_by_id = current_user.id
    @folder.position = next_position(@folder.parent_id) if @folder.position.blank? || @folder.position.zero?

    if @folder.save
      success_response(
        data: TeamFolderSerializer.serialize(@folder),
        message: 'Team folder created successfully',
        status: :created
      )
    else
      error_response(
        ApiErrorCodes::VALIDATION_ERROR,
        'Validation failed',
        details: @folder.errors.full_messages,
        status: :unprocessable_entity
      )
    end
  end

  def update
    if @folder.update(folder_params)
      success_response(
        data: TeamFolderSerializer.serialize(@folder),
        message: 'Team folder updated successfully'
      )
    else
      error_response(
        ApiErrorCodes::VALIDATION_ERROR,
        'Validation failed',
        details: @folder.errors.full_messages,
        status: :unprocessable_entity
      )
    end
  end

  def destroy
    @folder.destroy!
    success_response(
      data: { id: @folder.id },
      message: 'Team folder deleted successfully'
    )
  end

  private

  def fetch_folder
    @folder = TeamFolder.find(params[:id])
  end

  def folder_params
    params.require(:team_folder).permit(:name, :parent_id, :position)
  end

  def next_position(parent_id)
    (TeamFolder.where(parent_id: parent_id).maximum(:position) || -1) + 1
  end
end
