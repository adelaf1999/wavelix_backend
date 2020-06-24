class ChangeOrdersTableAttributes < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :drivers_rejected
    remove_column :orders, :unconfirmed_drivers
    add_column :orders, :drivers_rejected, :text, array: true, default: []
    add_column :orders, :unconfirmed_drivers, :text, array: true, default: []
  end
end
