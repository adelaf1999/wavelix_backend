class AddStatusToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :status, :integer, default: 1
  end
end
