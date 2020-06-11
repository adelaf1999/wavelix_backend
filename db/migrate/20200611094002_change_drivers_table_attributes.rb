class ChangeDriversTableAttributes < ActiveRecord::Migration[6.0]
  def change
    remove_column :drivers, :driver_mode_on
    add_column :drivers, :status, :integer, default: 0 # { offline: 0, online: 1 }
    add_column :drivers, :currency, :string, null: false
    add_column :drivers, :balance, :decimal, default: 0.0
  end
end
