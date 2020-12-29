class CreatePostCases < ActiveRecord::Migration[6.0]
  def change
    create_table :post_cases do |t|
      t.integer :post_id, null: false
      t.integer :review_status, default: 0
      t.text :admins_reviewed, array: true, default: []
      t.string :deleted_by, default: ''
      t.text :admins_reviewing, array: true, default: []
      t.timestamps
    end
  end
end
