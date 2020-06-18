class AddPhoneNumberVerifiedToCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :customer_users, :phone_number_verified, :boolean, default: false
  end
end
