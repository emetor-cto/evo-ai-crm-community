# frozen_string_literal: true

# Empty-string SKUs collide on the partial unique index (WHERE sku IS NOT NULL).
# Convert blanks to NULL so multiple products can omit SKU.
class NullifyBlankProductSkus < ActiveRecord::Migration[7.1]
  def up
    execute "UPDATE products SET sku = NULL WHERE sku IS NOT NULL AND btrim(sku) = ''"
    execute "UPDATE product_variants SET sku = NULL WHERE sku IS NOT NULL AND btrim(sku) = ''"
  end

  def down
    # Irreversible data fix
  end
end
