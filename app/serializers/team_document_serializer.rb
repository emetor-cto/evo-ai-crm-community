# frozen_string_literal: true

module TeamDocumentSerializer
  extend self

  def serialize(document, include_content: true)
    data = {
      id: document.id,
      title: document.title,
      folder_id: document.folder_id,
      position: document.position,
      created_by_id: document.created_by_id,
      updated_by_id: document.updated_by_id,
      created_at: document.created_at&.iso8601,
      updated_at: document.updated_at&.iso8601,
      attachments: serialize_attachments(document)
    }

    if include_content
      data[:content_json] = document.content_json || []
      data[:content_text] = document.content_text
    else
      data[:preview] = document.content_text.to_s.truncate(160)
    end

    data
  end

  def serialize_collection(documents, include_content: false)
    return [] unless documents

    documents.map { |document| serialize(document, include_content: include_content) }
  end

  private

  def serialize_attachments(document)
    document.attachments.map do |attachment|
      {
        id: attachment.id,
        file_type: attachment.file_type,
        file_url: attachment.file_url,
        download_url: attachment.download_url,
        thumb_url: attachment.thumb_url,
        extension: attachment.extension,
        fallback_title: attachment.fallback_title
      }
    end
  end
end
