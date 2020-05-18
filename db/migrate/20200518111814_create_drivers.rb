class CreateDrivers < ActiveRecord::Migration[6.0]

  def change

    create_table :drivers do |t|
      t.boolean :driver_mode_on, default: false
      t.integer :customer_id, null: false
      t.text :current_location, null: false
      t.string :country, null: false
      t.timestamps
    end

  end

end
