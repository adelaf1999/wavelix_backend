class AddStreetNameToStoreUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :store_users, :street_name, :string
  end
end
