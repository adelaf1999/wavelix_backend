class AddNameToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :name, :string, null: false
  end
end
