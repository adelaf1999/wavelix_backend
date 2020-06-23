class ModifyDriversTable < ActiveRecord::Migration[6.0]

  def change
    remove_column :drivers, :current_location
    remove_column :drivers, :country
    add_column :drivers, :latitude, :decimal, precision: 10, scale: 6, null: false
    add_column :drivers, :longitude, :decimal, precision: 10, scale: 6, null: false
    add_index :drivers, [:latitude, :longitude]
  end

end
