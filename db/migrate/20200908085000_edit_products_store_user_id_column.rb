class EditProductsStoreUserIdColumn < ActiveRecord::Migration[6.0]
  def change
    change_column :products, :store_user_id, :integer, null: false
  end
end
