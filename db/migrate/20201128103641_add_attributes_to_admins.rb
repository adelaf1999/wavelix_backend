class AddAttributesToAdmins < ActiveRecord::Migration[6.0]
  def change
    add_column :admins, :full_name, :string, null: false
    add_column :admins, :profile_photo, :text, null: false
    add_column :admins, :roles, :string
  end
end
