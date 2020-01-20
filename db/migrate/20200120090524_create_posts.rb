class CreatePosts < ActiveRecord::Migration[6.0]
  def change
    create_table :posts do |t|
      t.integer :profile_id, null: false
      t.string :caption
      t.integer :product_id
      t.integer :media_type, null: false
      t.text :media_file, null: false
      t.timestamps
    end
  end
end
