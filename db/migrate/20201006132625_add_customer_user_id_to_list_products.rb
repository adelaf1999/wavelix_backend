class AddCustomerUserIdToListProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :list_products, :customer_user_id, :integer, null: false
  end
end
