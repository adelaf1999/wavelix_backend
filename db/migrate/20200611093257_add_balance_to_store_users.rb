class AddBalanceToStoreUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :store_users, :balance, :decimal, default: 0.0
  end
end
