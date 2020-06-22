class ChangeDeliveryTimeLimitAttributeOrders < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :delivery_time_limit
    add_column :orders, :delivery_time_limit, :datetime
  end
end
