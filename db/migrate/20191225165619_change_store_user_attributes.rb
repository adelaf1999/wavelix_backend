class ChangeStoreUserAttributes < ActiveRecord::Migration[6.0]
  def change
    remove_column :store_users, :store_address
    add_column :store_users, :store_address, :text, :null => false
  end
end
