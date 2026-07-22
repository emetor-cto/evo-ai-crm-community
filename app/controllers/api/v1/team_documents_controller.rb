# frozen_string_literal: true

class Api::V1::TeamDocumentsController < Api::V1::BaseController
  include FileTypeHelper

  # Authenticated team members can manage shared notebooks.
  # Dedicated team_notes.* RBAC keys land when auth permissions are deployed.

  before_action :fetch_document, only: %i[show update destroy attach]

  MAX_ATTACHMENT_BYTES = 15.megabytes

  def index
    @team_documents = TeamDocument.includes(:attachments).ordered
    @team_documents = @team_documents.in_folder(params[:folder_id].presence) if params.key?(:folder_id)
    @team_documents = @team_documents.search(params[:q]) if params[:q].present?

    apply_pagination

    paginated_response(
      data: TeamDocumentSerializer.serialize_collection(@team_documents),
      collection: @team_documents,
      message: 'Team documents retrieved successfully'
    )
  end

  def show
    success_response(
      data: TeamDocumentSerializer.serialize(@document),
      message: 'Team document retrieved successfully'
    )
  end

  def create
    @document = TeamDocument.new(document_params)
    @document.created_by_id = current_user.id
    @document.updated_by_id = current_user.id
    @document.position = next_position(@document.folder_id) if @document.position.blank? || @document.position.zero?
    @document.title = 'Untitled' if @document.title.blank?

    if @document.save
      success_response(
        data: TeamDocumentSerializer.serialize(@document),
        message: 'Team document created successfully',
        status: :created
      )
    else
      error_response(
        ApiErrorCodes::VALIDATION_ERROR,
        'Validation failed',
        details: @document.errors.full_messages,
        status: :unprocessable_entity
      )
    end
  end

  def update
    @document.assign_attributes(document_params)
    @document.updated_by_id = current_user.id

    if @document.save
      success_response(
        data: TeamDocumentSerializer.serialize(@document),
        message: 'Team document updated successfully'
      )
    else
      error_response(
        ApiErrorCodes::VALIDATION_ERROR,
        'Validation failed',
        details: @document.errors.full_messages,
        status: :unprocessable_entity
      )
    end
  end

  def destroy
    @document.destroy!
    success_response(
      data: { id: @document.id },
      message: 'Team document deleted successfully'
    )
  end

  def attach
    file = params[:file]
    if file.blank?
      return error_response(
        ApiErrorCodes::VALIDATION_ERROR,
        'File is required',
        status: :unprocessable_entity
      )
    end

    if file.respond_to?(:size) && file.size.to_i > MAX_ATTACHMENT_BYTES
      return error_response(
        ApiErrorCodes::VALIDATION_ERROR,
        "Attachment exceeds the maximum allowed size (#{MAX_ATTACHMENT_BYTES / 1.megabyte} MB)",
        status: :unprocessable_entity
      )
    end

    attachment = @document.attachments.build(file_type: determine_file_type(file.content_type))
    attachment.fallback_title = file.original_filename
    attachment.file.attach(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    attachment.save!

    success_response(
      data: {
        id: attachment.id,
        url: attachment.file_url,
        file_url: attachment.file_url,
        download_url: attachment.download_url,
        thumb_url: attachment.thumb_url,
        file_type: attachment.file_type,
        filename: file.original_filename
      },
      message: 'Attachment uploaded successfully',
      status: :created
    )
  end

  private

  def fetch_document
    @document = TeamDocument.find(params[:id])
  end

  def document_params
    permitted = params.require(:team_document).permit(:title, :folder_id, :position)
    if params[:team_document].key?(:content_json)
      permitted[:content_json] = deep_to_unsafe_h(params[:team_document][:content_json])
    end
    permitted
  end

  def deep_to_unsafe_h(value)
    case value
    when ActionController::Parameters
      value.permit!.to_unsafe_h
    when Array
      value.map { |item| deep_to_unsafe_h(item) }
    when Hash
      value.transform_values { |item| deep_to_unsafe_h(item) }
    else
      value
    end
  end

  def next_position(folder_id)
    (TeamDocument.where(folder_id: folder_id).maximum(:position) || -1) + 1
  end

  def determine_file_type(content_type)
    file_type(content_type)
  end
end
