class AdminAccountMailer < ApplicationMailer

  def send_verification_code(email, verification_code)
    @verification_code = verification_code
    mail to: email, subject: 'Wavelix Verification Code'
  end

  def password_change_notice(email, notice)
    @notice = notice
    mail to: email, subject: 'Admin Password Changed'
  end

end