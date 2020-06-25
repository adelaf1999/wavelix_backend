class ChangeStoreArrivalTimeLimitAttribute < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :store_arrival_time_limit
    add_column :orders, :store_arrival_time_limit, :datetime
  end
end
