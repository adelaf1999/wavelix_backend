class AddAttributesToDrivers < ActiveRecord::Migration[6.0]

  def change
      add_column :drivers, :driver_license_pictures, :text, null: false
      add_column :drivers, :national_id_pictures, :text, null: false
      add_column :drivers, :profile_picture, :text, null: false
      add_column :drivers, :vehicle_registration_document_pictures, :text, null: false
  end

end
