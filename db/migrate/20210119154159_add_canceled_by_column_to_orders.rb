class AddCanceledByColumnToOrders < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :refunded_by
    add_column :orders, :canceled_by, :string, default: ''
  end
end
