class AddStoreUserIdToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :store_user_id, :integer, null:false
  end
end
