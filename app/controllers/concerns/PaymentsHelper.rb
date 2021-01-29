module PaymentsHelper

  Stripe.api_key = ENV.fetch('STRIPE_SECRET_KEY')


  def get_drivers_commission_fee
    5
  end

  def get_products_commission_fee
    5.9
  end


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