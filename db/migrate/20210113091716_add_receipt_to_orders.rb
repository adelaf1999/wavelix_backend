class AddReceiptToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :receipt, :text
  end
end
