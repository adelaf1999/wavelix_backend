class AddMaximumDeliveryDistanceToStoreUsers < ActiveRecord::Migration[6.0]

  def change
    add_column :store_users, :maximum_delivery_distance, :decimal
  end

end
