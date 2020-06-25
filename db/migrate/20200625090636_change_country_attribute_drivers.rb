class ChangeCountryAttributeDrivers < ActiveRecord::Migration[6.0]
  def change
    change_column :drivers, :country, :string, null: false
  end
end
