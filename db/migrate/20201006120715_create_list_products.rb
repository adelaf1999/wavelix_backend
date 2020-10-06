class CreateListProducts < ActiveRecord::Migration[6.0]
  def change
    create_table :list_products do |t|
      t.integer :list_id, null: false
      t.integer :product_id, null: false
      t.timestamps
    end
  end
end
