class AddAuthColumnsToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :uid, :string, default: '', null: false
    add_column :employees, :provider, :string, default: 'username', null: false
  end
end
