class PhoneVerificationsController < ApplicationController

  before_action :authenticate_user!

  include RegistrationHelper

  def is_phone_number_verified

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      @phone_number_verified = customer_user.phone_number_verified

    end

  end


  def verify

    if current_user.customer_user?

      is_valid = true

      required_params = [:code, :country, :phone_number]

      required_params.each do |p|

        if params[p] == nil || params[p] == ''

          is_valid = false

          @success = false

          break

        end

      end

      if is_valid

        code = params[:code]

        country = params[:country]

        phone_number = params[:phone_number]

        country_info = ISO3166::Country.new(country)

        if is_country_blocked?(country) || country_info == nil

          @success = false


        else

          country_code = country_info.country_code

          response = Authy::PhoneVerification.check(
              verification_code: code,
              country_code: country_code,
              phone_number: phone_number
          )

          if response.ok?

            customer_user = CustomerUser.find_by(customer_id: current_user.id)

            customer_user.update!(phone_number: "+#{country_code}#{phone_number}", phone_number_verified: true)

            @success = true


          else

            @success = false
            @message = 'Invalid code. Please try again'


          end


        end

      end


    end

  end


  def create

    if current_user.customer_user?


      is_valid = true

      required_params = [:country, :phone_number]

      required_params.each do |p|

        if params[p] == nil || params[p] == ''

          is_valid = false

          @success = false

          break

        end

      end


      if is_valid

        country = params[:country]

        phone_number = params[:phone_number]

        country_info = ISO3166::Country.new(country)

        if is_country_blocked?(country) || country_info == nil

          @success = false


        else

          country_code = country_info.country_code

          response = Authy::PhoneVerification.start(
              via: 'sms',
              country_code: country_code,
              phone_number: phone_number
          )


          if response.ok?

            @success = true

          else

            @success = false
            @message = 'An error occurred. Please try again'


          end

        end


      end


    end

  end





end
