class AddAdminsRequestedBlockToProfiles < ActiveRecord::Migration[6.0]
  def change
    remove_column :profiles, :admins_requested_blocked
    add_column :profiles, :admins_requested_block, :text, array: true, default: []
  end
end
