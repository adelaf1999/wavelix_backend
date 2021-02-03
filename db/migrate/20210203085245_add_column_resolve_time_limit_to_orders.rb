class AddColumnResolveTimeLimitToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :resolve_time_limit, :datetime
  end
end
