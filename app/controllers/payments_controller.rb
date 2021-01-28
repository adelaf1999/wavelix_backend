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


      number = params[:number]

      exp_month = params[:exp_month]

      exp_year = params[:exp_year]

      cvc = params[:cvc]


      if number != nil && exp_month != nil &&  exp_year != nil && cvc != nil

        begin


          # If the customer already has a payment method, delete it to create a new one

          delete_existing_card(stripe_customer_token)


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
              saving_customer_card: true,
              customer_user_id: customer_user.id
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

            @error_code = 1

            @error_message = 'Error adding card. Please try again.'

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

          @error_message = e.error.message.blank? ? 'Error adding card. Please try again.' :  e.error.message


        rescue => e

          @success = false

          @error_code = 1

          @error_message = 'Error adding card. Please try again.'

        end




      else

        @success = false

        @error_code = 1

        @error_message = 'Error adding card. Please try again.'

      end

    end

  end

end
