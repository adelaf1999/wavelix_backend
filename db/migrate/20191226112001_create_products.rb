class CreateProducts < ActiveRecord::Migration[6.0]
  def change
    create_table :products do |t|
      t.string :name, :null => false
      t.string :description, :null => false
      t.decimal :price, :null => false
      t.text :main_picture, :null => false
      t.integer :stock_quantity
      t.boolean :product_available, :default => true
      t.timestamps
    end
  end
end
