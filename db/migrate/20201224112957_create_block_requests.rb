class CreateBlockRequests < ActiveRecord::Migration[6.0]
  def change
    create_table :block_requests do |t|
      t.string :admin_name, null: false
      t.string :reason, null: false
      t.integer :profile_id, null: false
      t.timestamps
    end
  end
end
