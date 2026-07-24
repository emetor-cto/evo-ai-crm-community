# frozen_string_literal: true

class AddCommissionToProducts < ActiveRecord::Migration[7.1]
  def change
    unless column_exists?(:products, :commission)
      add_column :products, :commission, :decimal, precision: 10, scale: 2, null: false, default: 0.0
    end

    unless check_constraint_exists?(:products, name: 'products_commission_non_negative')
      add_check_constraint :products, 'commission >= 0', name: 'products_commission_non_negative'
    end
  end
end
