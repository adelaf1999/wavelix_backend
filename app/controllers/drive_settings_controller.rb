class DriveSettingsController < ApplicationController

  before_action :authenticate_user!


  def index

    if current_user.customer_user?

      current_driver = CustomerUser.find_by(customer_id: current_user.id).driver

      if current_driver == nil

        @success = false

      elsif !current_driver.payment_source_setup?

        @success = false

      else

        @success = true

        stripe_customer_token = current_driver.stripe_customer_token

        payment_methods =  Stripe::PaymentMethod.list({customer: stripe_customer_token, type: 'card'}).data

        payment_method = payment_methods[0]

        card_info = payment_method.card

        @card_info = {
            brand: card_info.brand,
            last4: card_info.last4
        }


      end

    else

      @success = false

    end


  end

end
