class AdminAccountMailerPreview < ActionMailer::Preview

  def send_verification_code
    email = 'adelwaboufakher@gmail.com'
    verification_code = '123456'
    AdminAccountMailer.send_verification_code(email, verification_code)
  end


  def password_change_notice
    email = 'adelwaboufakher@gmail.com'
    notice = 'Adel Abou Fakher has changed the password of Wajih Abou Fakher.'
    AdminAccountMailer.password_change_notice(email, notice)
  end


  def roles_changed_notice
    email = 'adelwaboufakher@gmail.com'
    notice = 'Adel Abou Fakher updated the roles of Farida Abou Fakher to the following: order manager, profile manager.'
    AdminAccountMailer.password_change_notice(email, notice)
  end

  def account_deleted_notice
    email = 'adelwaboufakher@gmail.com'
    notice = 'Adel Abou Fakher deleted the account of Wajih abou fakher with email wajih@example.com.'
    AdminAccountMailer.account_deleted_notice(email, notice)
  end

  def admin_account_created
    email = 'adelwaboufakher@gmail.com'
    notice = 'Adel Abou Fakher created an account for Wajih Abou Fakher with the following roles: Order manager, Profile manager'
    AdminAccountMailer.account_created_notice(email, notice)
  end

  def store_registered_notice
    email = 'adelwaboufakher@gmail.com'
    store_user_id = 1
    AdminAccountMailer.store_registered_notice(email, store_user_id)
  end

  def driver_registered_notice
    email = 'adelwaboufakher@gmail.com'
    driver_id = 1
    AdminAccountMailer.driver_registered_notice(email, driver_id)
  end

  def store_profile_block_request
    email = 'adelwaboufakher@gmail.com'
    profile_id = 1
    AdminAccountMailer.store_profile_block_request(email, profile_id)
  end

  def store_profile_status_changed
    email = 'adelwaboufakher@gmail.com'
    message = 'This is a test message'
    AdminAccountMailer.store_profile_status_changed(email, message)
  end

  def post_case_opened_notice
    email = 'adelwaboufakher@gmail.com'
    message = 'This is a test message'
    post_case_id = 1
    AdminAccountMailer.post_case_opened_notice(email, message, post_case_id)
  end

end