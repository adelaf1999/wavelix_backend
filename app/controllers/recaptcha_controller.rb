require 'net/https'

class RecaptchaController < ApplicationController

  def verify_recaptcha_token

    token = params[:token]

    if !token.blank?

      uri = URI.parse("https://www.google.com/recaptcha/api/siteverify?secret=#{ENV.fetch('RECAPTCHA_SECRET_KEY')}&response=#{token}")

      response = Net::HTTP.get_response(uri)

      data = JSON.parse(response.body)


      success = data['success']

      if success

        score = data['score']

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
