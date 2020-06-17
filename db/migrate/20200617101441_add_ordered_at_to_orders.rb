class AddOrderedAtToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :ordered_at, :time, null: false
  end
end
