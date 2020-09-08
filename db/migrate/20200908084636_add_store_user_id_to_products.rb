class AddStoreUserIdToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :store_user_id, :integer
  end
end
