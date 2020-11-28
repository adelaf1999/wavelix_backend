class AddRenewVerificationAtToAdmins < ActiveRecord::Migration[6.0]
  def change
    change_column :admins, :renew_verification_code_at, :datetime, null: false
  end
end
