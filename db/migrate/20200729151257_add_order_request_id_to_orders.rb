class AddOrderRequestIdToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :order_request_id, :integer, unique: true
  end
end
