class AddCountryToCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    change_column :customer_users, :country_of_residence, :string
    add_column :customer_users, :country, :string
  end
end
