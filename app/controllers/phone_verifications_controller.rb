class PhoneVerificationsController < ApplicationController

  before_action :authenticate_user!

  include CountriesHelper

  def is_phone_number_verified

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      @phone_number_verified = customer_user.phone_number_verified

    end

  end


  def can_request_sms

    # error_codes

    # { 0: PHONE_NUMBER_EXISTS_ERROR, 1: CANT_REQUEST_SMS_ERROR }

    if current_user.customer_user?

      is_valid = true

      required_params = [:country, :number]

      required_params.each do |p|

        if params[p] == nil || params[p] == ''

          is_valid = false

          @success = false

          break

        end

      end


      if is_valid

        country = params[:country]

        number = params[:number]

        country_info = ISO3166::Country.new(country)

        if country_info != nil

          country_code = country_info.country_code

          phone_number = PhoneNumber.find_by(number: "#{country_code}#{number}")


          if !can_use_phone_number?(country_code, number)

            @success = false

            @error_code = 0


          else


            if phone_number == nil || phone_number.can_request_sms?

              @success = true

            else

              # Phone number exists but still cant make phone request

              @success = false

              @error_code = 1



            end


          end








        end


      end


    end

  end


  def verify

    if current_user.customer_user?

      is_valid = true

      required_params = [:code, :country, :number]

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

        number = params[:number]

        country_info = ISO3166::Country.new(country)

        if is_country_blocked?(country) || country_info == nil

          @success = false


        else

          country_code = country_info.country_code




          if can_use_phone_number?(country_code, number)

            response = Authy::PhoneVerification.check(
                verification_code: code,
                country_code: country_code,
                phone_number: number
            )


            # puts response

            if response.ok?

              customer_user = CustomerUser.find_by(customer_id: current_user.id)

              customer_user.update!(phone_number: "+#{country_code}#{number}", phone_number_verified: true)

              @success = true

            else

              @success = false

              @message = 'Invalid code. Please try again'


            end


          else

            @success = false

            @message = 'Phone number is already being used'

          end




        end

      end


    end

  end


  def create

    if current_user.customer_user?

      is_valid = true

      required_params = [:country, :number]

      required_params.each do |p|

        if params[p] == nil || params[p] == ''

          is_valid = false

          @success = false

          break

        end

      end


      if is_valid

        country = params[:country]

        number = params[:number]

        country_info = ISO3166::Country.new(country)

        if is_country_blocked?(country) || country_info == nil

          @success = false


        else

          country_code = country_info.country_code

          phone_number = PhoneNumber.find_by(number: "#{country_code}#{number}")





          if can_use_phone_number?(country_code, number)


            if phone_number == nil

              response = Authy::PhoneVerification.start(
                  via: 'sms',
                  country_code: country_code,
                  phone_number: number
              )

              # puts response


              if response.ok?

                @success = true

                next_request_at = (DateTime.now.utc + 60.seconds).to_datetime

                PhoneNumber.create!(number: "#{country_code}#{number}", next_request_at: next_request_at)

              else

                @success = false
                @message = 'An error occurred. Please try again'


              end





            else

              if phone_number.can_request_sms?

                response = Authy::PhoneVerification.start(
                    via: 'sms',
                    country_code: country_code,
                    phone_number: number
                )

                # puts response


                if response.ok?

                  @success = true

                  next_request_at = (DateTime.now.utc + 60.seconds).to_datetime

                  phone_number.update!(next_request_at: next_request_at)

                else

                  @success = false
                  @message = 'An error occurred. Please try again'


                end


              else

                @success = false


              end


            end



          else

            @success = false

            @message = 'Phone number is already being used'

          end



        end


      end


    end

  end


  def index

    @phone_extensions = get_phone_extensions

  end


  private

  def can_use_phone_number?(country_code, number)

    # If the phone number is not associated with any other customer_user account then allow phone number to be used

    CustomerUser.find_by(phone_number: "+#{country_code}#{number}").nil?

  end



end
