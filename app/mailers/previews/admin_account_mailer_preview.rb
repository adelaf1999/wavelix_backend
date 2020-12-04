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

end