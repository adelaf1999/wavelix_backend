class AddProductPicturesAttributesToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :product_pictures_attributes, :text
  end
end
