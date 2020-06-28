class ChangeOrdersTableAttributesNew < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :driver_canceled_order
    add_column :orders, :drivers_canceled_order, :text, array: true, default: []
  end
end
