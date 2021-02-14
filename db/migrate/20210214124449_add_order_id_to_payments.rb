class AddOrderIdToPayments < ActiveRecord::Migration[6.0]
  def change
    add_column :payments, :order_id, :integer, null: false
  end
end
