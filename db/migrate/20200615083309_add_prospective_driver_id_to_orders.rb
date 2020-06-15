class AddProspectiveDriverIdToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :prospective_driver_id, :integer
  end
end
