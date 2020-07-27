module PaymentsHelper

  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')


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