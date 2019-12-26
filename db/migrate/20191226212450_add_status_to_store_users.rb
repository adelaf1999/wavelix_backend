class AddStatusToStoreUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :store_users, :status, :integer, default: 0
  end
end
