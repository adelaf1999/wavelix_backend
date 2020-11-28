class AdminAccountMailer < ApplicationMailer

  def send_verification_code(email, verification_code)
    @verification_code = verification_code
    mail to: email, subject: 'Wavelix Verification Code'
  end

end