class CreateProfiles < ActiveRecord::Migration[6.0]
  def change
    create_table :profiles do |t|
      t.integer :user_id, null: false
      t.integer :privacy, default: 0
      t.boolean :follower_system_visible, default: true
      t.text :profile_picture
      t.string :profile_bio
      t.timestamps
    end
  end
end
