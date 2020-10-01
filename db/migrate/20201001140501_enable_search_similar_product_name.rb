class EnableSearchSimilarProductName < ActiveRecord::Migration[6.0]
  def change
    enable_extension :pg_trgm
    add_index :products, :name, opclass: :gin_trgm_ops, using: :gin
  end
end
