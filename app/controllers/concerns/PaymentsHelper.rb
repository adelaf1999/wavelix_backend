module PaymentsHelper

  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')



  def authorize_amount_usd(amount_cents, customer_token, payment_method_id, metadata)

    Stripe::PaymentIntent.create(
        {
            amount: amount_cents,
            currency: 'usd',
            customer: customer_token,
            payment_method: payment_method_id,
            setup_future_usage: 'on_session',
            metadata: metadata,
            capture_method: 'manual'
        }
    )

  end


  def capture_order_payment_intent(payment_intent_id)


    pending_orders = Order.where(stripe_payment_intent: payment_intent_id, status: 1)

    amount_to_capture = 0

    pending_orders.each do |order|

      order_price_cents = order.total_price * 100

      order_price_cents = order_price_cents.round.to_i

      amount_to_capture += order_price_cents

    end

    payment_intent = Stripe::PaymentIntent.capture(
        payment_intent_id,
        amount_to_capture: amount_to_capture
    )


    payment_intent.status == 'succeeded'


  end


  def cancel_payment_intent(order)

    # Before canceling a payment intent, get all other orders with the same stripe payment intent

    # As the order passed that are pending. If the are no other pending orders, then cancel the payment intent.

    stripe_payment_intent = order.stripe_payment_intent

    other_pending_orders = Order.where(stripe_payment_intent: stripe_payment_intent, status: 1).where.not(id: order.id)

    if other_pending_orders.length == 0

      Stripe::PaymentIntent.cancel(order.stripe_payment_intent)

    end

  end

  def refund_order(order)

    payment_intent = Stripe::PaymentIntent.retrieve(order.stripe_payment_intent)

    balance_transaction = Stripe::BalanceTransaction.retrieve(payment_intent.charges.data.first.balance_transaction)


    total_payment = balance_transaction.amount.to_f / 100.to_f

    fee_payment = balance_transaction.fee.to_f / 100.to_f


    order_total = order.total_price.to_f.round(2)

    order_fee = ( order_total / total_payment  ) * fee_payment

    order_net = order_total - order_fee



    order_net = order_net * 100

    order_net = order_net.round.to_i


    Stripe::Refund.create({
                              payment_intent: order.stripe_payment_intent,
                              amount: order_net
                          })


  end


  def get_customer_card_info(customer_token)

    payment_methods =  Stripe::PaymentMethod.list({customer: customer_token, type: 'card'}).data

    if payment_methods.length > 0

      payment_method = payment_methods[0]

      payment_method.card

    else

      nil

    end

  end


  def get_customer_card(customer_token)

    payment_methods =  Stripe::PaymentMethod.list({customer: customer_token, type: 'card'}).data

    payment_method = payment_methods[0]

    payment_method.id


  end

  def delete_existing_card(customer_token)

    payment_methods =  Stripe::PaymentMethod.list({customer: customer_token, type: 'card'}).data

    if payment_methods.length > 0

      payment_method = payment_methods[0]

      Stripe::PaymentMethod.detach(payment_method.id)

    end

  end


  def delete_other_existing_cards(customer_token, payment_method_id)

    saved_payment_methods =  Stripe::PaymentMethod.list({customer: customer_token, type: 'card'}).data

    if saved_payment_methods.length > 1

      saved_payment_methods.each do |saved_payment_method|

        if saved_payment_method.id != payment_method_id

          Stripe::PaymentMethod.detach(saved_payment_method.id)

        end

      end

    end


  end


  def is_payment_method?(token)

    begin

      Stripe::PaymentMethod.retrieve(token)

      true

    rescue => e

      false

    end

  end


  def create_setup_intent(customer_token, metadata)

    Stripe::SetupIntent.create(
        {
            customer: customer_token,
            usage: 'on_session',
            metadata: metadata
        }
    )

  end

  def has_saved_card?(customer_token)

    payment_methods =  Stripe::PaymentMethod.list({customer: customer_token, type: 'card'}).data

    payment_methods.length > 0

  end



  def create_stripe_token_customer(name, customer_user_id)

    user = Stripe::Customer.create({
                                       name: name,
                                       description: 'Customer Account',
                                       metadata: {
                                           customer_user_id: customer_user_id
                                       }
                                   })

    user['id']


  end


  def create_stripe_token_driver(name, driver_id)

    user = Stripe::Customer.create({
                                       name: name,
                                       description: 'Driver Account',
                                       metadata: {
                                           driver_id: driver_id
                                       }
                                   })

    user['id']


  end


  def destroy_stripe_customer(customer_token)

    Stripe::Customer.delete(customer_token)

  end

end