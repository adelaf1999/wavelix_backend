class CreateLists < ActiveRecord::Migration[6.0]
  def change
    create_table :lists do |t|
      t.string :name, null: false
      t.integer :privacy, null: false
      t.integer :customer_user_id, null: false
      t.boolean :is_default, default: false
      t.timestamps
    end
  end
end
