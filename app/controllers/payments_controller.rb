class PaymentsController < ApplicationController

  before_action :authenticate_user!

  include PaymentsHelper # Stripe lib becomes usable when including this since it contains API key config

  def add_card

    # error_codes {0 : AUTHENTICATION_REQUIRED, 1: PAYMENT_METHOD_SETUP_FAILED, 2: CARD_ERROR }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      stripe_customer_token = customer_user.stripe_customer_token

      setup_intent_id = params[:setup_intent_id]

      token_id = params[:token_id]

      if setup_intent_id != nil && token_id != nil && !setup_intent_id.empty? && !token_id.empty?

        begin


          # Check if customer already has payment source, if has one replace

          card = Stripe::Customer.create_source(stripe_customer_token, {source: token_id})

          result = Stripe::SetupIntent.confirm(setup_intent_id, {payment_method: card.id})

          status = result.status

          if status == 'succeeded'

            # has_card: true

            @success = true

          elsif status == 'requires_action'

            # has_card: true/false?

            @success = false

            @error_code = 0

            @next_action = result.next_action


          elsif status == 'requires_payment_method'

            @success = false

            @error_code = 1

          end

        rescue Stripe::CardError => e

          # puts "Status is: #{e.http_status}"
          # puts "Type is: #{e.error.type}"
          # puts "Charge ID is: #{e.error.charge}"
          # # The following fields are optional
          # puts "Code is: #{e.error.code}" if e.error.code
          # puts "Decline code is: #{e.error.decline_code}" if e.error.decline_code
          # puts "Param is: #{e.error.param}" if e.error.param
          # puts "Message is: #{e.error.message}" if e.error.message

          @success = false

          @error_code = 2

          if e.error.message

            @error_message =  e.error.message

          end

        rescue Stripe::RateLimitError => e
          @success = false
        rescue Stripe::InvalidRequestError => e
          @success = false
        rescue Stripe::AuthenticationError => e
          @success = false
        rescue Stripe::APIConnectionError => e
          @success = false
        rescue Stripe::StripeError => e
          @success = false
        rescue => e
          @success = false
        end

      else

        @success = false

      end

    end

  end

end
