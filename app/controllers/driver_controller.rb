class DriverController < ApplicationController

  include OrderHelper

  include MoneyHelper

  include PaymentsHelper

  before_action :authenticate_user!


  def add_card

    # error_codes {0 : AUTHENTICATION_REQUIRED }

    if current_user.customer_user?

      current_driver = CustomerUser.find_by(customer_id: current_user.id).driver

      if current_driver == nil

        @success = false

        @message = 'Error adding card'

      elsif !current_driver.unblocked?

        @success = false

        @message = 'Cannot replace existing card while account is blocked'

      else

        stripe_customer_token = current_driver.stripe_customer_token

        number = params[:number]

        exp_month = params[:exp_month]

        exp_year = params[:exp_year]

        cvc = params[:cvc]

        if number != nil && exp_month != nil &&  exp_year != nil && cvc != nil

          begin


            payment_method = Stripe::PaymentMethod.create({
                                                              type: 'card',
                                                              card: {
                                                                  number: number,
                                                                  exp_month: exp_month,
                                                                  exp_year: exp_year,
                                                                  cvc: cvc,
                                                              },
                                                          })

            card = payment_method.card



            setup_intent_id = create_setup_intent(stripe_customer_token, {
                saving_driver_card: true,
                driver_id: current_driver.id
            }).id


            result = Stripe::SetupIntent.confirm(
                setup_intent_id,
                {
                    payment_method: payment_method.id,
                    return_url: Rails.env.production? ? ENV.fetch('CARD_AUTH_PRODUCTION_REDIRECT_URL') : ENV.fetch('CARD_AUTH_DEVELOPMENT_REDIRECT_URL')
                }
            )


            status = result.status

            if status == 'succeeded'

              delete_other_existing_cards(stripe_customer_token, payment_method.id)

              @success = true

              @card_info = {
                  brand: card.brand,
                  last4: card.last4
              }


            elsif status == 'requires_action' || result.next_action != nil

              @success = false

              @error_code = 0

              next_action = result.next_action

              @redirect_url = next_action.redirect_to_url.url

            elsif status == 'requires_payment_method'

              @success = false

              @message = 'Error adding card'

            end


          rescue Stripe::CardError => e

            @success = false

            @message =  e.error.message.blank? ? 'Error adding card' :  e.error.message


          rescue => e

            @success = false

            @message = 'Error adding card'

          end


        else

          @success = false

          @message = 'Error adding card'

        end

      end


    else

      @success = false

      @message = 'Error adding card'

    end


  end

  def register

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      current_driver = customer_user.driver

      if current_driver == nil


        missing_params = false

        req_params = [
            :currency,
            :name,
            :latitude,
            :longitude,
            :driver_license_pictures,
            :national_id_pictures,
            :profile_picture,
            :vehicle_registration_document_pictures
        ]


        driver_params = params.permit(
            :currency,
            :name,
            :latitude,
            :longitude,
            {driver_license_pictures: []},
            {national_id_pictures: []},
            :profile_picture,
            {vehicle_registration_document_pictures: []},
        )

        req_params.each do |p|

          if driver_params[p] == nil

            missing_params = true

            break

          end

        end



        if !missing_params

          currency = driver_params[:currency]
          name = driver_params[:name]
          latitude = driver_params[:latitude]
          longitude = driver_params[:longitude]
          driver_license_pictures = driver_params[:driver_license_pictures]
          national_id_pictures = driver_params[:national_id_pictures]
          profile_picture = driver_params[:profile_picture]
          vehicle_registration_pictures = driver_params[:vehicle_registration_document_pictures]

          driver = Driver.new

          if !is_currency_valid?(currency)

            @success = false

            @message = 'The currency selected is not available'

            return

          else

            driver.currency = currency

          end

          if name.blank?

            @success = false

            @message = 'Name cannot be blank'

            return

          else

            driver.name = name

          end

          if is_decimal_number?(latitude) && is_decimal_number?(longitude)

            latitude = latitude.to_d

            longitude = longitude.to_d

            geo_location = Geocoder.search([latitude, longitude])

            if geo_location.size > 0

              geo_location_country_code = geo_location.first.country_code

              driver.country = geo_location_country_code

              driver.latitude = latitude

              driver.longitude = longitude


            else

              @success = false

              @message = 'Error determining your location'

              return

            end



          else

            @success = false

            @message = 'Error determining your location'

            return

          end


          if !are_uploaded_pictures_valid?(driver_license_pictures) ||
              !are_uploaded_pictures_valid?(national_id_pictures) ||
              !are_uploaded_pictures_valid?(vehicle_registration_pictures)


            @success = false

            @message = 'Some uploaded pictures are invalid'

            return

          else

            driver.driver_license_pictures = driver_license_pictures
            driver.national_id_pictures = national_id_pictures
            driver.vehicle_registration_document_pictures = vehicle_registration_pictures

          end


          if !profile_picture.is_a?(ActionDispatch::Http::UploadedFile)  || !is_picture_valid?(profile_picture)

            @success = false

            @message = 'The uploaded profile picture is invalid'

            return

          else

            driver.profile_picture = profile_picture

          end


          driver.customer_user_id = customer_user.id

          if driver.save!

            @success = true

            ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
                is_registered: true,
                driver_verified: driver.driver_verified,
                name: driver.name,
                profile_picture_url: driver.profile_picture.url,
                has_saved_card: driver.payment_source_setup?
            }


            ActionCable.server.broadcast 'driver_accounts_channel', {
                new_driver_registered: true
            }


            send_registered_notification(driver.id)

          else

            @success = false

            @message = 'Error creating account'

          end



        else

          @success = false

          @message = 'Error creating account'

        end




      else

        @success = false

        @message = 'A driver account was already registered'

      end

    else

      @success = false

      @message = 'Error creating account'

    end

  end

  def profile_picture

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      current_driver = customer_user.driver

      if current_driver != nil

        @profile_picture = current_driver.profile_picture.url

      end


    end


  end


  def index

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      current_driver = customer_user.driver

      if current_driver == nil

        @is_registered = false

        @currencies = get_currencies

      else

        @is_registered = true

        @driver_verified = current_driver.driver_verified

        @name = current_driver.name

        @profile_picture_url = current_driver.profile_picture.url

        @has_saved_card = current_driver.payment_source_setup?

      end

    end

  end

  private


  def send_registered_notification(driver_id)

    # Send email to all account managers and root admins when a new driver signs up

    admins = Admin.role_root_admins + Admin.role_account_managers

    admins = admins.uniq

    admins.each do |admin|

      AdminAccountMailer.delay.driver_registered_notice(admin.email, driver_id)

    end

  end

  def is_picture_valid?(picture)

    filename = picture.original_filename.split(".")
    extension = filename[filename.length - 1]
    valid_extensions = ["png" , "jpeg", "jpg", "gif"]
    valid_extensions.include?(extension)

  end

  def are_uploaded_pictures_valid?(pictures)

    valid = true

    pictures.each do |picture|

      if picture.is_a?(ActionDispatch::Http::UploadedFile)

        filename = picture.original_filename.split(".")

        extension = filename[filename.length - 1]

        valid_extensions = ["png" , "jpeg", "jpg", "gif"]


        if !valid_extensions.include?(extension)

          valid = false

          break

        end

      else
        valid = false
        break

      end

    end

    valid

  end


end
