class AddDriverVerifiedToDrivers < ActiveRecord::Migration[6.0]
  def change
    add_column :drivers, :driver_verified, :boolean, default: false
  end
end
