class AddColumnsToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :admins_reviewing, :text, array: true, default: []
    add_column :orders, :confirmed_by, :string, default: ''
    add_column :orders, :refunded_by, :string, default: ''
  end
end
