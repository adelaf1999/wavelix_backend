class AddStoreIdToStoreUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :store_users, :store_id, :integer
  end
end
