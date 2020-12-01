require 'net/https'

class RecaptchaController < ApplicationController

  def verify_recaptcha_token

    token = params[:token]

    if !token.blank?

      secret_key = params[:is_admin].blank? ? ENV.fetch('RECAPTCHA_SECRET_KEY') : ENV.fetch('ADMIN_RECAPTCHA_SECRET_KEY')

      uri = URI.parse("https://www.google.com/recaptcha/api/siteverify?secret=#{secret_key}&response=#{token}")

      response = Net::HTTP.get_response(uri)

      data = JSON.parse(response.body)


      success = data['success']

      if success

        score = data['score']

        puts "SCORE IS #{score}"

        if score >= 0.5

          @success = true

        else

          @success = false

        end

      else

        @success = false

      end


    else

      @success = false

    end

  end

end
