class CreatePostReports < ActiveRecord::Migration[6.0]
  def change
    create_table :post_reports do |t|
      t.integer :user_id, null: false
      t.integer :post_id, null: false
      t.integer :post_case_id, null: false
      t.string :additional_information, default: ''
      t.integer :report_type , null: false
      t.timestamps
    end
  end
end
