class AddCurrentCountryToDrivers < ActiveRecord::Migration[6.0]
  def change
    add_column :drivers, :current_country, :string, null: false
  end
end
