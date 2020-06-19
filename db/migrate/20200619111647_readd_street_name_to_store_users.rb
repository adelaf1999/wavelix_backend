class ReaddStreetNameToStoreUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :store_users, :street_name, :string, default: ''
  end
end
