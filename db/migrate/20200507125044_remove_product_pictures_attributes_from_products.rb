class RemoveProductPicturesAttributesFromProducts < ActiveRecord::Migration[6.0]
  def change

    remove_column :products, :product_pictures_attributes

  end
end
