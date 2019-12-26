class CreateCategories < ActiveRecord::Migration[6.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.integer :parent_id
      t.integer :store_user_id, null: false
      t.timestamps
    end
  end
end
