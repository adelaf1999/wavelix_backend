class AddProductAttributesToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :product_attributes, :text
  end
end
