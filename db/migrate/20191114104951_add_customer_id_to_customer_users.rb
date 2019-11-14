class AddCustomerIdToCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :customer_users, :customer_id, :integer
  end
end
