class AddAttributesToStoreUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :store_users, :review_status, :integer, default: 0
    add_column :store_users, :verified_by, :string, default: ''
    add_column :store_users, :admins_reviewing, :text, array: true, default: []
    add_column :store_users, :admins_declined, :text, array: true, default: []
  end
end
