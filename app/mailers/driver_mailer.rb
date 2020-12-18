class DriverMailer < ApplicationMailer

  def account_verified(email, driver_name)
    @driver_name = driver_name
    mail to: email, subject: 'Wavelix Driver Account Verified'
  end

end
