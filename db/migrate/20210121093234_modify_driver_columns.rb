class ModifyDriverColumns < ActiveRecord::Migration[6.0]
  def change
    remove_column :drivers, :account_blocked
    add_column :drivers, :account_status, :integer, default: 0
    add_column :drivers, :stripe_customer_token, :string, null: false
    add_column :drivers, :admins_resolving, :text, array: true, default: []
  end
end
