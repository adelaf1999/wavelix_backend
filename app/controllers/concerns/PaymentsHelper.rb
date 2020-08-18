module PaymentsHelper

  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')


  def get_drivers_commission_fee
    5
  end

  def get_products_commission_fee
    5.9
  end

  def refund_order(order)

    payment_intent = Stripe::PaymentIntent.retrieve(order.stripe_payment_intent)

    balance_transaction = Stripe::BalanceTransaction.retrieve(payment_intent.charges.data.first.balance_transaction)


    # Net and total amount in USD

    total_amount = balance_transaction.amount.to_f / 100.to_f

    net_amount = balance_transaction.net / 100.to_f


    order_total = order.total_price.to_f.round(2)

    refund_amount = (order_total / total_amount)  * net_amount


    # Convert refund amount to cents

    refund_amount = refund_amount * 100

    refund_amount = refund_amount.round.to_i

    
    Stripe::Refund.create({
                              payment_intent: order.stripe_payment_intent,
                              amount: refund_amount
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