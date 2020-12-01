class ModifyExpireAtColumn < ActiveRecord::Migration[6.0]
  def change
    change_column :admins, :expire_at, :datetime, null: false
  end
end
