class AddCountryToDrivers < ActiveRecord::Migration[6.0]
  def change
    add_column :drivers, :country, :string
  end
end
