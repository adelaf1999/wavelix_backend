class PaymentsController < ApplicationController

  before_action :authenticate_user!

  include PaymentsHelper

  def add_card

    # error_codes {0 : AUTHENTICATION_REQUIRED, 1: CARD_ERROR }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      stripe_customer_token = customer_user.stripe_customer_token

      setup_intent_id = params[:setup_intent_id]

      token_id = params[:token_id]

      if setup_intent_id != nil && token_id != nil && !setup_intent_id.empty? && !token_id.empty?

        if is_setup_intent_valid?(setup_intent_id) && is_token_id_valid?(token_id)

          begin

            # If the customer already has a payment source, delete it to create a new one

            delete_existing_card(stripe_customer_token)

            card = Stripe::Customer.create_source(stripe_customer_token, {source: token_id})

            result = Stripe::SetupIntent.confirm(
                setup_intent_id,
                {
                    payment_method: card.id,
                    return_url: Rails.env.production? ? ENV.fetch('CARD_AUTH_PRODUCTION_REDIRECT_URL') : ENV.fetch('CARD_AUTH_DEVELOPMENT_REDIRECT_URL')
                }
            )

            status = result.status

            if status == 'succeeded'

              @success = true

            elsif status == 'requires_action'

              @success = false

              @error_code = 0

              next_action = result.next_action

              @redirect_url = next_action.redirect_to_url.url


            elsif status == 'requires_payment_method'

              @success = false

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

            @error_code = 1

            if e.error.message

              @error_message =  e.error.message

            end

          rescue => e

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

end
