class AddPhoneNumberToCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :customer_users, :phone_number, :string
  end
end
