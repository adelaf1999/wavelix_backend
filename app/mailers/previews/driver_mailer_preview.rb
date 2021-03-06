module Previews

  class DriverMailerPreview < ActionMailer::Preview

    def account_verified
      email = 'adelwaboufakher@gmail.com'
      driver_name = 'Wajih Abou Fakher'
      DriverMailer.account_verified(email, driver_name)
    end

  end

end