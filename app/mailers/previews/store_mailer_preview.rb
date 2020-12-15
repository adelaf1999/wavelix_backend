class StoreMailerPreview < ActionMailer::Preview

  def account_verification
    email = 'adelwaboufakher@gmail.com'
    store_owner_name = 'Adel'
    StoreMailer.account_verification(email, store_owner_name)
  end

  def account_verified
    email = 'adelwaboufakher@gmail.com'
    store_owner_name = 'Adel Abou Fakher'
    store_name = 'Nike'
    StoreMailer.account_verified(email, store_owner_name, store_name)
  end

end