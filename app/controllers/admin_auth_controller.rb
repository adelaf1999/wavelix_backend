class AdminAuthController < ApplicationController


  def resend_verification_code

    admin = Admin.find_by(email: params[:email])

    if admin != nil

      @success = true

      if DateTime.now.utc > admin.renew_verification_code_at

        renew_verification_code_at = DateTime.now.utc + 10.minutes

        verification_code = rand.to_s[2..7]

        admin.update!(verification_code: verification_code, renew_verification_code_at: renew_verification_code_at)

      else

        verification_code = admin.verification_code

      end

      AdminAccountMailer.delay.send_verification_code(admin.email, verification_code)

    else

      @success = false

    end


  end


  def check_email


    admin = Admin.find_by(email: params[:email])

    if admin != nil

      @success = true

      if DateTime.now.utc > admin.renew_verification_code_at

        renew_verification_code_at = DateTime.now.utc + 10.minutes

        verification_code = rand.to_s[2..7]

        admin.update!(verification_code: verification_code, renew_verification_code_at: renew_verification_code_at)

      else

        verification_code = admin.verification_code

      end


      AdminAccountMailer.delay.send_verification_code(admin.email, verification_code)


    else

      @success = false

      @message = 'Email does not exist'

    end


  end


end
