# frozen_string_literal: true

# == Schema Information
#
# Table name: team_folders
#
#  id            :uuid             not null, primary key
#  name          :string(255)      not null
#  parent_id     :uuid
#  position      :integer          default(0), not null
#  created_by_id :uuid             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class TeamFolder < ApplicationRecord
  belongs_to :parent, class_name: 'TeamFolder', optional: true
  has_many :children, class_name: 'TeamFolder', foreign_key: :parent_id, dependent: :nullify, inverse_of: :parent
  has_many :documents, class_name: 'TeamDocument', foreign_key: :folder_id, dependent: :nullify, inverse_of: :folder

  validates :name, presence: true, length: { maximum: 255 }
  validates :created_by_id, presence: true
  validate :parent_is_not_self

  scope :ordered, -> { order(:position, :name) }
  scope :roots, -> { where(parent_id: nil) }

  private

  def parent_is_not_self
    return if parent_id.blank? || id.blank?
    return unless parent_id == id

    errors.add(:parent_id, 'cannot be the folder itself')
  end
end
