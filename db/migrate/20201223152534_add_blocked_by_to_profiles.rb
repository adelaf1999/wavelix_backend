class AddBlockedByToProfiles < ActiveRecord::Migration[6.0]
  def change
    add_column :profiles, :blocked_by, :string, default: ''
  end
end
