class CustomerSettingsController < ApplicationController

  before_action :authenticate_user!

  include MoneyHelper

  include PaymentsHelper
  

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

        stripe_customer_token = customer_user.stripe_customer_token

        if customer_user.payment_source_setup?

          card_info = get_customer_card_info(stripe_customer_token)

          @card_info = {
              brand: card_info.brand,
              last4: card_info.last4
          }


        end


      end


    end

  end


end
