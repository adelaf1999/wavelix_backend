class AddAccountBlockedToDrivers < ActiveRecord::Migration[6.0]
  def change
    add_column :drivers, :account_blocked, :boolean, default: false
  end
end
