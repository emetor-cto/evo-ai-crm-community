class CreateDashboardChecklists < ActiveRecord::Migration[7.1]
  def change
    create_table :dashboard_checklists, id: :uuid do |t|
      t.string :title, null: false, limit: 255
      t.boolean :active, null: false, default: true
      t.uuid :created_by_id, null: false

      t.timestamps
    end

    add_index :dashboard_checklists, :created_by_id
    add_index :dashboard_checklists, :active

    create_table :dashboard_checklist_items, id: :uuid do |t|
      t.references :dashboard_checklist, type: :uuid, null: false, foreign_key: true, index: true
      t.string :title, null: false, limit: 255
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :dashboard_checklist_items, [:dashboard_checklist_id, :position],
              name: 'index_dashboard_checklist_items_on_checklist_and_position'

    create_table :dashboard_checklist_assignments, id: :uuid do |t|
      t.references :dashboard_checklist, type: :uuid, null: false, foreign_key: true, index: true
      t.uuid :user_id, null: false

      t.timestamps
    end

    add_index :dashboard_checklist_assignments, [:dashboard_checklist_id, :user_id],
              unique: true,
              name: 'index_dashboard_checklist_assignments_unique'
    add_index :dashboard_checklist_assignments, :user_id

    create_table :dashboard_checklist_completions, id: :uuid do |t|
      t.references :dashboard_checklist_item, type: :uuid, null: false, foreign_key: true,
                                             index: { name: 'index_dashboard_checklist_completions_on_item_id' }
      t.uuid :user_id, null: false
      t.date :completed_on, null: false

      t.timestamps
    end

    add_index :dashboard_checklist_completions, [:dashboard_checklist_item_id, :user_id, :completed_on],
              unique: true,
              name: 'index_dashboard_checklist_completions_unique'
    add_index :dashboard_checklist_completions, [:user_id, :completed_on]
  end
end
