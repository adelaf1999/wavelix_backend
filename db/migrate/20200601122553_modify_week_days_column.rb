class ModifyWeekDaysColumn < ActiveRecord::Migration[6.0]
  def change
    change_column :days, :week_day, :string, null: false
  end
end
