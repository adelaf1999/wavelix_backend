class AddPushTokenToUsersAndEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :push_token, :string, default: ''
    add_column :employees, :push_token, :string, default: ''
  end
end
