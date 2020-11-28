class AddVerificationCodeToAdmins < ActiveRecord::Migration[6.0]
  def change
    add_column :admins, :verification_code, :string, default: ''
  end
end
