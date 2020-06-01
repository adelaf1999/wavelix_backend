class AddScheduleIdToDays < ActiveRecord::Migration[6.0]
  def change
    add_column :days, :schedule_id, :integer, null: false
  end
end
