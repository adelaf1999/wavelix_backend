class RemoveCurrentCountryFromDrivers < ActiveRecord::Migration[6.0]
  def change
    remove_column :drivers, :current_country
  end
end
