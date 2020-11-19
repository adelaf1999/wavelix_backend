class StoreMailerPreview < ActionMailer::Preview

  def account_verification
    email = 'adelwaboufakher@gmail.com'
    store_owner_name = 'Adel'
    StoreMailer.account_verification(email, store_owner_name)
  end

end