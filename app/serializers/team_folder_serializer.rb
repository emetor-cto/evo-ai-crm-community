# frozen_string_literal: true

module TeamFolderSerializer
  extend self

  def serialize(folder, children_map: nil)
    data = {
      id: folder.id,
      name: folder.name,
      parent_id: folder.parent_id,
      position: folder.position,
      created_by_id: folder.created_by_id,
      created_at: folder.created_at&.iso8601,
      updated_at: folder.updated_at&.iso8601
    }

    if children_map
      children = children_map[folder.id] || []
      data[:children] = children.map { |child| serialize(child, children_map: children_map) }
    end

    data
  end

  def serialize_collection(folders)
    return [] unless folders

    folders.map { |folder| serialize(folder) }
  end

  def serialize_tree(folders = TeamFolder.ordered.to_a)
    children_map = folders.group_by(&:parent_id)
    roots = children_map[nil] || []
    roots.map { |folder| serialize(folder, children_map: children_map) }
  end
end
