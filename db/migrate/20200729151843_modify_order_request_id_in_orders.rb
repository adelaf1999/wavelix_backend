class ModifyOrderRequestIdInOrders < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :order_request_id
    add_column :orders, :order_request_id, :integer, unique: true, null: false
  end
end
