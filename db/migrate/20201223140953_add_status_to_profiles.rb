class AddStatusToProfiles < ActiveRecord::Migration[6.0]
  def change
    add_column :profiles, :status, :integer, default: 0
  end
end
