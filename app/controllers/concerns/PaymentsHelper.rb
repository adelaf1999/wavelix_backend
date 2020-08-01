module PaymentsHelper

  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')


  def get_drivers_commission_fee
    5
  end

  def get_products_commission_fee
    5.9
  end

  def refund_order(order)

    # Refer to stripe docs for more info: https://stripe.com/docs/refunds

    total_price_usd = order.total_price

    total_price_cents = total_price_usd * 100

    total_price_cents = total_price_cents.round.to_i

    Stripe::Refund.create({
                              payment_intent: order.stripe_payment_intent,
                              amount: total_price_cents
                          })


  end


  def get_customer_card_info(customer_token)

    customer = Stripe::Customer.retrieve(customer_token)

    card_id = customer.default_source

    Stripe::Customer.retrieve_source(customer_token, card_id)

  end


  def get_customer_card(customer_token)

    customer = Stripe::Customer.retrieve(customer_token)

    customer.default_source


  end

  def delete_existing_card(customer_token)

    customer = Stripe::Customer.retrieve(customer_token)

    customer_card = customer.default_source

    if customer_card != nil

      Stripe::Customer.delete_source(customer_token, customer_card)

    end

  end

  def is_token_id_valid?(token_id)

    begin

      Stripe::Token.retrieve(token_id)

      true

    rescue => e

      false

    end


  end

  def is_setup_intent_valid?(setup_intent_id)

    begin

      Stripe::SetupIntent.retrieve(setup_intent_id)

      true

    rescue => e

       false

    end




  end

  def create_setup_intent(customer_token)


    Stripe::SetupIntent.create({customer: customer_token, usage: 'on_session'})


    # Commented Code Below is used when testing for 3D secure implmentation

   # Stripe::SetupIntent.create({customer: customer_token, usage: 'on_session', payment_method_options: {
   #     card: {
   #         request_three_d_secure: 'any'
   #     }
   # }})

  end

  def has_saved_card?(customer_token)

    customer = Stripe::Customer.retrieve(customer_token)

    customer.default_source != nil


  end

  def create_stripe_customer(name, email, customer_user_id)

    customer = Stripe::Customer.create({
                                            name: name,
                                            email: email,
                                            metadata: {
                                                customer_user_id: customer_user_id
                                            }
                                       })

    customer['id']

  end

  def destroy_stripe_customer(customer_token)

    Stripe::Customer.delete(customer_token)

  end

end