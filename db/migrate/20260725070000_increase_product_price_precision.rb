# frozen_string_literal: true

# Product prices were decimal(10, 2), which silently rounds values like 5.799 → 5.80.
# Bump scale so the catalog keeps the exact value entered (up to 6 decimal places).
class IncreaseProductPricePrecision < ActiveRecord::Migration[7.1]
  def up
    change_column :products, :default_price, :decimal, precision: 16, scale: 6, null: false, default: 0.0
    change_column :products, :commission, :decimal, precision: 16, scale: 6, null: false, default: 0.0
    change_column :product_variants, :price_override, :decimal, precision: 16, scale: 6
    change_column :pipeline_item_products, :locked_unit_price, :decimal, precision: 16, scale: 6, null: false
  end

  def down
    change_column :products, :default_price, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    change_column :products, :commission, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    change_column :product_variants, :price_override, :decimal, precision: 10, scale: 2
    change_column :pipeline_item_products, :locked_unit_price, :decimal, precision: 10, scale: 2, null: false
  end
end
