class AdminAccountMailer < ApplicationMailer

  def send_verification_code(email, verification_code)
    @verification_code = verification_code
    mail to: email, subject: 'Wavelix Verification Code'
  end

  def password_change_notice(email, notice)
    @notice = notice
    mail to: email, subject: 'Admin Password Changed'
  end

  def roles_changed_notice(email, notice)
    @notice = notice
    mail to: email, subject: 'Admin Roles Changed'
  end

  def account_deleted_notice(email, notice)
    @notice = notice
    mail to: email, subject: 'Admin Account Deleted'
  end

  def account_created_notice(email, notice)
    @notice = notice
    mail to: email, subject: 'Admin Account Created'
  end


  def store_registered_notice(email, store_user_id)
    @store_user_id = store_user_id
    @view_store_link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/store-accounts/store_user_id=#{store_user_id}"
    mail to: email, subject: 'New Store Registered'
  end

  def driver_registered_notice(email, driver_id)
    @driver_id = driver_id
    @view_store_link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/driver-accounts/driver_id=#{driver_id}"
    mail to: email, subject: 'New Driver Registered'
  end

  def store_profile_block_request(email, profile_id)
    @view_profile_link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/profiles/profile_id=#{profile_id}"
    mail to: email, subject: 'Store Profile Block Request'
  end

  def store_profile_status_changed(email, message)
    @message = message
    mail to: email, subject: 'Store Profile Block Request'
  end

end