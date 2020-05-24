class AddStoreUserIdToCartItems < ActiveRecord::Migration[6.0]
  def change
    add_column :cart_items, :store_user_id, :integer
  end
end
