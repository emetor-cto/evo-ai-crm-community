# frozen_string_literal: true

# == Schema Information
#
# Table name: team_documents
#
#  id            :uuid             not null, primary key
#  title         :string(255)      default("Untitled"), not null
#  folder_id     :uuid
#  content_json  :jsonb            not null
#  content_text  :text             default(""), not null
#  position      :integer          default(0), not null
#  created_by_id :uuid             not null
#  updated_by_id :uuid
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class TeamDocument < ApplicationRecord
  belongs_to :folder, class_name: 'TeamFolder', optional: true, inverse_of: :documents
  has_many :attachments, as: :attachable, dependent: :destroy

  validates :title, presence: true, length: { maximum: 255 }
  validates :created_by_id, presence: true

  scope :ordered, -> { order(:position, :title) }
  scope :in_folder, ->(folder_id) { where(folder_id: folder_id) }
  scope :search, lambda { |query|
    return all if query.blank?

    sanitized = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where('title ILIKE :q OR content_text ILIKE :q', q: sanitized)
  }

  before_validation :normalize_content_json
  before_save :refresh_content_text

  private

  def normalize_content_json
    self.content_json = [] if content_json.nil?
  end

  def refresh_content_text
    self.content_text = extract_plain_text(content_json)
  end

  def extract_plain_text(blocks)
    return '' unless blocks.is_a?(Array)

    blocks.filter_map do |block|
      next unless block.is_a?(Hash)

      content = block['content'] || block[:content]
      next unless content.is_a?(Array)

      content.filter_map { |node| node.is_a?(Hash) ? (node['text'] || node[:text]) : nil }.join(' ')
    end.join("\n")
  end
end
