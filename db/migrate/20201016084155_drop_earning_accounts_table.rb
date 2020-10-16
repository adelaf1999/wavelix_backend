class DropEarningAccountsTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :earning_accounts
  end
end
