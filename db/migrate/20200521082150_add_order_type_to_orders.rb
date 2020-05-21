class AddOrderTypeToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :order_type, :integer, null: false
  end
end
