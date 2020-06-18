class RemoveStreetNameFromStoreUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :store_users, :street_name
  end
end
