class ChangePaymentsTable < ActiveRecord::Migration[6.0]
  def change
    remove_column :payments, :store_user_id
    remove_column :payments, :driver_id
    add_column :payments, :store_user_id, :integer
    add_column :payments, :driver_id, :integer
  end
end
