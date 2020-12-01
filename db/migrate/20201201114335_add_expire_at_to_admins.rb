class AddExpireAtToAdmins < ActiveRecord::Migration[6.0]
  def change
    add_column :admins, :expire_at, :datetime
  end
end
