module PaymentsHelper

  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')

  def create_setup_intent(customer_token)

   Stripe::SetupIntent.create({customer: customer_token, usage: 'on_session', payment_method_options: {
       card: {
           request_three_d_secure: 'any'
       }
   }})

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