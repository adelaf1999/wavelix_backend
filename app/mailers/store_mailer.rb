class StoreMailer < ApplicationMailer

  def account_verification(email, store_owner_name)
    @store_owner_name = store_owner_name
    mail to: email, subject: 'Business Account Verification'
  end

  def account_verified(email, store_owner_name, store_name)
    @store_owner_name = store_owner_name
    @store_name = store_name
    mail to: email, subject: 'Wavelix Business Account Verified'
  end

end