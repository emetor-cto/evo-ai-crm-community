# frozen_string_literal: true

class CreateTeamNotebook < ActiveRecord::Migration[7.1]
  def change
    create_table :team_folders, id: :uuid do |t|
      t.string :name, null: false, limit: 255
      t.uuid :parent_id
      t.integer :position, null: false, default: 0
      t.uuid :created_by_id, null: false

      t.timestamps
    end

    add_index :team_folders, :parent_id
    add_index :team_folders, :created_by_id
    add_index :team_folders, [:parent_id, :position],
              name: 'index_team_folders_on_parent_and_position'
    add_foreign_key :team_folders, :team_folders, column: :parent_id, on_delete: :nullify

    create_table :team_documents, id: :uuid do |t|
      t.string :title, null: false, limit: 255, default: 'Untitled'
      t.uuid :folder_id
      t.jsonb :content_json, null: false, default: []
      t.text :content_text, null: false, default: ''
      t.integer :position, null: false, default: 0
      t.uuid :created_by_id, null: false
      t.uuid :updated_by_id

      t.timestamps
    end

    add_index :team_documents, :folder_id
    add_index :team_documents, :created_by_id
    add_index :team_documents, :updated_by_id
    add_index :team_documents, [:folder_id, :position],
              name: 'index_team_documents_on_folder_and_position'
    add_foreign_key :team_documents, :team_folders, column: :folder_id, on_delete: :nullify
  end
end
