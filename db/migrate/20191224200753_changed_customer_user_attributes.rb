class ChangedCustomerUserAttributes < ActiveRecord::Migration[6.0]
  def change
    remove_column :customer_users, :residential_address
    add_column :customer_users, :home_address, :text, :null => false
    add_column :customer_users, :building_name, :string
    add_column :customer_users, :apartment_floor, :integer
  end
end
