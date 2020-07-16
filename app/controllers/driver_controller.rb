class DriverController < ApplicationController

  include OrderHelper

  include MoneyHelper

  before_action :authenticate_user!


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
            @message = 'Invalid currency'
            return

          else

            driver.currency = currency

          end

          if name.empty?

            @success = false
            @message = 'Name cannot be empty'
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
              @message = 'Invalid location'
              return

            end



          else

            @success = false
            @message = 'Invalid location'
            return

          end


          if !are_uploaded_pictures_valid?(driver_license_pictures) ||
              !are_uploaded_pictures_valid?(national_id_pictures) ||
              !are_uploaded_pictures_valid?(vehicle_registration_pictures)


            @success = false
            @message = 'Some uploaded pictures were invalid'
            return

          else

            driver.driver_license_pictures = driver_license_pictures
            driver.national_id_pictures = national_id_pictures
            driver.vehicle_registration_document_pictures = vehicle_registration_pictures

          end


          if !profile_picture.is_a?(ActionDispatch::Http::UploadedFile)  || !is_picture_valid?(profile_picture)

            @success = false
            @message = 'Invalid profile picture'
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
                profile_picture_url: driver.profile_picture.url
            }

          else

            @success = false
            @message = 'Error registering driver'

          end



        else

          @success = false
          @message = 'Missing required params'

        end




      else

        @success = false

        @message = 'Already Registered'

      end


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

      end

    end

  end

  private

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
