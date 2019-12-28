class MakeChange < ActiveRecord::Migration[6.0]
  def change
    remove_column :products, :product_pictures
    add_column :products, :product_pictures, :text
  end
end
