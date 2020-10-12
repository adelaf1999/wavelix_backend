class CustomerSettingsController < ApplicationController

  before_action :authenticate_user!

  include MoneyHelper

  include PaymentsHelper

  include OrderHelper

  def update_home_address

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        latitude = params[:latitude]

        longitude = params[:longitude]

        if !latitude.blank? && !longitude.blank?

          if is_decimal_number?(latitude) && is_decimal_number?(longitude)

            latitude = latitude.to_d

            longitude = longitude.to_d

            geo_location = Geocoder.search([latitude, longitude])

            if geo_location.size > 0

              @success = true

              @home_address = { latitude: latitude, longitude: longitude }

              customer_user.update!(home_address: @home_address)

            else

              @success = false

            end

          else

            @success = false


          end

        else

          @success = false

        end


      else

        head :unauthorized

        return


      end


    end


  end


  def update_apartment_floor

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      apartment_floor = params[:apartment_floor]

      if apartment_floor != nil

        customer_user.update!(apartment_floor: apartment_floor)

      end

    end

  end

  def update_building_name

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      building_name = params[:building_name]

      if building_name != nil

        customer_user.update!(building_name: building_name)

      end

    end

  end


  def change_default_currency

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        currency = params[:currency]

        if currency != nil && is_currency_valid?(currency)

          customer_user.update!(default_currency: currency)

          @default_currency = currency

          @success = true

        else

          @success = false

        end

      else

        @success = false

      end



    end


  end

  def index

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        @default_currency = customer_user.default_currency

        @currencies = get_currencies

        @building_name = customer_user.building_name

        @apartment_floor = customer_user.apartment_floor

        stripe_customer_token = customer_user.stripe_customer_token

        if customer_user.payment_source_setup?

          card_info = get_customer_card_info(stripe_customer_token)

          @card_info = {
              brand: card_info.brand,
              last4: card_info.last4
          }


        end

        @home_address = customer_user.home_address


      end


    end

  end





end
