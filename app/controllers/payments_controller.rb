class PaymentsController < ApplicationController

  before_action :authenticate_user!

  include PaymentsHelper


  def check_card_setup

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      customer_token = customer_user.stripe_customer_token

      if has_saved_card?(customer_token)

          @has_saved_card = true

      else

          @has_saved_card = false

      end


    end

  end




  def destroy_card

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      customer_token = customer_user.stripe_customer_token

      delete_existing_card(customer_token)

    end


  end

  def add_card

    # error_codes {0 : AUTHENTICATION_REQUIRED, 1: CARD_ERROR }

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      stripe_customer_token = customer_user.stripe_customer_token

      token_id = params[:token_id]

      if token_id != nil && !token_id.empty?

        begin

          # If the customer already has a payment method, delete it to create a new one

          delete_existing_card(stripe_customer_token)

          if is_payment_method?(token_id)

            payment_method = Stripe::PaymentMethod.attach(token_id, {customer: stripe_customer_token})

            card = payment_method.card


          else


            payment_method  = Stripe::PaymentMethod.create({type: 'card', card: {token: token_id}})

            card = payment_method.card


          end


          setup_intent_id = create_setup_intent(stripe_customer_token).id

          result = Stripe::SetupIntent.confirm(
              setup_intent_id,
              {
                  payment_method: payment_method.id,
                  return_url: Rails.env.production? ? ENV.fetch('CARD_AUTH_PRODUCTION_REDIRECT_URL') : ENV.fetch('CARD_AUTH_DEVELOPMENT_REDIRECT_URL')
              }
          )

          status = result.status

          if status == 'succeeded'

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

    end

  end

end
