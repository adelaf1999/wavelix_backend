class AddRolesToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :roles, :string
  end
end
