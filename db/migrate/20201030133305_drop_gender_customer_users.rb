class DropGenderCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :customer_users, :gender
  end
end
