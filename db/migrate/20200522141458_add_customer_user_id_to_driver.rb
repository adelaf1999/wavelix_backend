class AddCustomerUserIdToDriver < ActiveRecord::Migration[6.0]
  def change
    add_column :drivers, :customer_user_id, :integer, null: false
    remove_column :drivers, :customer_id
  end
end
