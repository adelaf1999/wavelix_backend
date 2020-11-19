class StoreMailer < ApplicationMailer

  def account_verification(email, store_owner_name)
    @store_owner_name = store_owner_name
    mail to: email, subject: 'Business Account Verification'
  end

end