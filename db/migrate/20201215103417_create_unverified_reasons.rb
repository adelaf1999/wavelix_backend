class CreateUnverifiedReasons < ActiveRecord::Migration[6.0]
  def change
    create_table :unverified_reasons do |t|
      t.string :admin_name, null: false
      t.string :reason, null: false
      t.integer :store_user_id
      t.integer :driver_id
      t.timestamps
    end
  end
end
