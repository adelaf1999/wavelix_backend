class AddCountryToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :country, :string, null: false
  end
end
