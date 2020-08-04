class ChangeApartmentFloorColumnCustomerUsers < ActiveRecord::Migration[6.0]
  def change
    change_column :customer_users, :apartment_floor, :string
  end
end
