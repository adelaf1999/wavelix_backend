class AdminAccountMailerPreview < ActionMailer::Preview

  def send_verification_code
    email = 'adelwaboufakher@gmail.com'
    verification_code = '123456'
    AdminAccountMailer.send_verification_code(email, verification_code)
  end

end