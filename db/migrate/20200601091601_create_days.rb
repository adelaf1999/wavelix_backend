class CreateDays < ActiveRecord::Migration[6.0]
  def change
    create_table :days do |t|
      t.string :open_at
      t.string :close_at
      t.integer :week_day, null: false
      t.boolean :closed, default: false
      t.timestamps
    end
  end
end
