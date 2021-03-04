require 'net/https'

class RecaptchaController < ApplicationController

  def verify_recaptcha_token

    token = params[:token]

    if !token.blank?

      is_admin = params[:is_admin]

      secret_key = fetch_secret_key(is_admin)


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

  private

  def fetch_secret_key(is_admin)

    if is_admin.blank?


      if Rails.env.development?

        ENV.fetch('DEVELOPMENT_WEB_RECAPTCHA_SECRET_KEY')

      else

        ENV.fetch('PRODUCTION_WEB_RECAPTCHA_SECRET_KEY')

      end


    else


      if Rails.env.development?

        ENV.fetch('DEVELOPMENT_ADMIN_RECAPTCHA_SECRET_KEY')

      else

        ENV.fetch('PRODUCTION_ADMIN_RECAPTCHA_SECRET_KEY')

      end


    end


  end


end
