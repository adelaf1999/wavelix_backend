Stripe.api_key             = ENV.fetch('STRIPE_SECRET_KEY')
StripeEvent.signing_secret = ENV.fetch('STRIPE_SIGNING_SECRET')


StripeEvent.configure do |events|

  events.subscribe 'payment_intent.payment_failed' do |event|

    customer_user = CustomerUser.find_by(stripe_customer_token: event.data.object.customer)

    if customer_user != nil

      # sanity check

      ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {payment_intent_success: false}


    end


  end



  events.subscribe 'payment_intent.succeeded' do |event|

    metadata = event.data.object.metadata.to_hash

    order_request_id = metadata[:order_request_id]

    customer_user = CustomerUser.find_by(stripe_customer_token: event.data.object.customer)

    payment_intent_id = event.data.object.id

    if order_request_id == nil


      order_request_ids = metadata[:order_request_ids]

      if order_request_ids != nil && customer_user != nil


        order_request_ids = eval(order_request_ids)

        payment_intent_success = false


        order_request_ids.each do |id|

          order_request = OrderRequest.find_by(id: id)

          if OrderRequest.create_order(order_request, payment_intent_id)

            payment_intent_success = true

          end

        end


        if payment_intent_success

          cart = customer_user.cart

          ActionCable.server.broadcast "cart_#{cart.id}_user_#{customer_user.customer_id}_channel", {payment_intent_success: true}


        end


      end



    else

      order_request = OrderRequest.find_by(id: order_request_id)


      if order_request != nil && customer_user != nil

        if OrderRequest.create_order(order_request, payment_intent_id)

          ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {payment_intent_success: true}

        end



      end


    end





  end





  events.subscribe 'setup_intent.succeeded' do |event|

    payment_method = Stripe::PaymentMethod.retrieve(event.data.object.payment_method)

    card = payment_method.card

    metadata = event.data.object.metadata.to_h

    stripe_customer_token =  event.data.object.customer

    if !metadata.blank?

      saving_customer_card = metadata[:saving_customer_card]

      saving_driver_card = metadata[:saving_driver_card]

      if saving_customer_card && !metadata[:customer_user_id].blank?

        customer_user_id = metadata[:customer_user_id]

        customer_user = CustomerUser.find_by(id: customer_user_id)

        ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {setup_intent_success: true}

        ActionCable.server.broadcast "customer_settings_#{customer_user.id}_channel", {
            setup_intent_success: true,
            card_info: {
                brand: card.brand,
                last4: card.last4
            }
        }

      elsif saving_driver_card && !metadata[:driver_id].blank?


        # Delete other existing cards if present

        saved_payment_methods =  Stripe::PaymentMethod.list({customer: stripe_customer_token, type: 'card'}).data

        if saved_payment_methods.length > 1

          saved_payment_methods.each do |saved_payment_method|

            if saved_payment_method.id != payment_method.id

              Stripe::PaymentMethod.detach(saved_payment_method.id)

            end

          end

        end

        driver_id = metadata[:driver_id]

        driver = Driver.find_by(id: driver_id)

        ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
            finished_registration: true
        }

        ActionCable.server.broadcast "drive_settings_channel_#{driver.customer_user_id}", {
            setup_intent_success: true,
            card_info: {
                brand: card.brand,
                last4: card.last4
            }
        }


      end

    end


  end


  events.subscribe 'setup_intent.setup_failed' do |event|


    metadata = event.data.object.metadata.to_h

    if !metadata.blank?

      saving_customer_card = metadata[:saving_customer_card]

      saving_driver_card = metadata[:saving_driver_card]

      if saving_customer_card && !metadata[:customer_user_id].blank?

        customer_user_id = metadata[:customer_user_id]

        customer_user = CustomerUser.find_by(id: customer_user_id)

        ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {setup_intent_success: false}

        ActionCable.server.broadcast "customer_settings_#{customer_user.id}_channel", {setup_intent_success: false}

      elsif saving_driver_card && !metadata[:driver_id].blank?

        driver_id = metadata[:driver_id]

        driver = Driver.find_by(id: driver_id)

        ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
            finished_registration: false
        }

        ActionCable.server.broadcast "drive_settings_channel_#{driver.customer_user_id}", {
            setup_intent_success: false
        }

      end


    end

  end




end