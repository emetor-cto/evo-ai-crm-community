class CreateSalesAnalyticsDashboards < ActiveRecord::Migration[7.1]
  def change
    create_table :sales_analytics_dashboards, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :kind, null: false, limit: 40
      t.integer :year, null: false
      t.jsonb :data, null: false, default: {}
      t.uuid :updated_by_id
      t.timestamps
    end

    add_index :sales_analytics_dashboards, [:kind, :year], unique: true,
              name: 'index_sales_analytics_dashboards_on_kind_and_year'
    add_index :sales_analytics_dashboards, :kind
    add_index :sales_analytics_dashboards, :updated_by_id
  end
end
