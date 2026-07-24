# frozen_string_literal: true

class CreatePipelineTaskTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :pipeline_task_templates, id: :uuid do |t|
      t.string :title, null: false, limit: 255
      t.text :description
      t.integer :task_type, null: false, default: 0
      t.integer :priority, null: false, default: 1
      t.integer :due_in_days
      t.boolean :active, null: false, default: true
      t.uuid :created_by_id, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :pipeline_task_templates, :active
    add_index :pipeline_task_templates, :created_by_id
    add_index :pipeline_task_templates, [:active, :position],
              name: 'index_pipeline_task_templates_on_active_and_position'
  end
end
