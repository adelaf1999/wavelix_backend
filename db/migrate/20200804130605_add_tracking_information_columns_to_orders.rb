class AddTrackingInformationColumnsToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :tracking_website_url, :string, default: ''
    add_column :orders, :tracking_number, :string, default: ''
  end
end
