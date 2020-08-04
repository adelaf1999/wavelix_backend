class ChangeCustomerUserBuildingFloorColumns < ActiveRecord::Migration[6.0]
  def change
    change_column :customer_users, :building_name, :string, default: ''
    change_column :customer_users, :apartment_floor, :string, default: ''
  end
end
