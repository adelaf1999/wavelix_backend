class CreateSchedules < ActiveRecord::Migration[6.0]
  def change
    create_table :schedules do |t|
      t.integer :store_user_id, null: false
      t.timestamps
    end
  end
end
