class AddProductPicturesToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :product_pictures, :text
  end
end
