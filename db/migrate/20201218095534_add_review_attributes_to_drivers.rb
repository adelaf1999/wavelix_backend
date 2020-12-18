class AddReviewAttributesToDrivers < ActiveRecord::Migration[6.0]
  def change
    add_column :drivers, :review_status, :integer, default: 0
    add_column :drivers, :verified_by, :string, default: ''
    add_column :drivers, :admins_reviewing, :text, array: true, default: []
    add_column :drivers, :admins_declined, :text, array: true, default: []
  end
end
