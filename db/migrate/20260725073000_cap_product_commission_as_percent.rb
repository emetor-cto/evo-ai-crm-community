# frozen_string_literal: true

# Commission on products is now a percentage (0–100). Fixed BRL amounts above 100
# would fail validation — reset them so existing rows remain editable.
class CapProductCommissionAsPercent < ActiveRecord::Migration[7.1]
  def up
    return unless column_exists?(:products, :commission)

    execute <<~SQL.squish
      UPDATE products
      SET commission = 0
      WHERE commission > 100
    SQL
  end

  def down
    # Irreversible data fix
  end
end
