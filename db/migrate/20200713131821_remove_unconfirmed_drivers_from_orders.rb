class RemoveUnconfirmedDriversFromOrders < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :unconfirmed_drivers
  end
end
