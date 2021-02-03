Stripe.api_key             = ENV.fetch('STRIPE_SECRET_KEY')
StripeEvent.signing_secret = ENV.fetch('STRIPE_SIGNING_SECRET')


StripeEvent.configure do |events|

  events.subscribe 'payment_intent.payment_failed' do |event|

    metadata = event.data.object.metadata.to_h


    if !metadata.blank?

      charging_customer_card = metadata[:charging_customer_card]

      charging_driver_card = metadata[:charging_driver_card]

      if charging_customer_card && !metadata[:customer_user_id].blank?

        customer_user_id = metadata[:customer_user_id]

        customer_user = CustomerUser.find_by(id: customer_user_id)

        if !metadata[:order_request_id].blank?

          order_request_id = metadata[:order_request_id]

          order_request = OrderRequest.find_by(id: order_request_id)

          order_request.destroy!

          ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {payment_intent_success: false}

        elsif !metadata[:order_request_ids].blank?

          order_request_ids = metadata[:order_request_ids]

          order_request_ids = eval(order_request_ids)

          order_request_ids.each do |id|

            order_request = OrderRequest.find_by(id: id)

            order_request.destroy!

          end


        end

      elsif charging_driver_card && !metadata[:driver_id].blank? && !metadata[:order_id].blank?

        driver_id = metadata[:driver_id]

        order_id = metadata[:order_id]

        order = Order.find_by(id: order_id)

        driver = Driver.find_by(id: driver_id)

        drivers_rejected = order.get_drivers_rejected


        if order.pending? && order.driver_id == nil && order.prospective_driver_id == driver.id && !drivers_rejected.include?(driver.id)

          drivers_rejected.push(driver.id)

          order.update!(drivers_rejected: drivers_rejected)

          FindNewDriverJob.perform_later(order.id)

        end


        ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
            accept_order_request_success: false,
            message: 'Error authorizing amount from card. Please try again or change the card in the settings.'
        }


      end


    end



  end



  events.subscribe 'payment_intent.amount_capturable_updated' do |event|

    include DriveHelper

    include PaymentsHelper

    metadata = event.data.object.metadata.to_h

    payment_intent_id = event.data.object.id

    if !metadata.blank?

      charging_customer_card = metadata[:charging_customer_card]

      charging_driver_card = metadata[:charging_driver_card]

      if charging_customer_card && !metadata[:customer_user_id].blank?

        customer_user_id = metadata[:customer_user_id]

        customer_user = CustomerUser.find_by(id: customer_user_id)

        if !metadata[:order_request_id].blank?

          order_request_id = metadata[:order_request_id]

          order_request = OrderRequest.find_by(id: order_request_id)

          if OrderRequest.create_order(order_request, payment_intent_id)

            ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {payment_intent_success: true}

          end


        elsif !metadata[:order_request_ids].blank?

          order_request_ids = metadata[:order_request_ids]

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


      elsif charging_driver_card && !metadata[:driver_id].blank? && !metadata[:order_id].blank?


        driver_id = metadata[:driver_id]

        order_id = metadata[:order_id]


        order = Order.find_by(id: order_id)

        driver = Driver.find_by(id: driver_id)

        drivers_rejected = order.get_drivers_rejected

        driver_payment_intent = Stripe::PaymentIntent.retrieve(payment_intent_id)


        if order.canceled? || drivers_rejected.include?(driver.id) || !driver.unblocked?

          Stripe::PaymentIntent.cancel(driver_payment_intent.id)

          ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
              accept_order_request_success: false,
              message: 'Order has been canceled.'
          }

        else


          order_payment_intent = Stripe::PaymentIntent.retrieve(order.stripe_payment_intent)


          if order_payment_intent.status == 'requires_capture'


            if capture_order_payment_intent(order_payment_intent.id)

              ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
                  accept_order_request_success: true
              }

              driver_accept_order_success(driver, order, driver_payment_intent.id)


            else

              ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
                  accept_order_request_success: false,
                  message: 'Order has been canceled.'
              }


              Stripe::PaymentIntent.cancel(driver_payment_intent.id)

              driver_accept_order_failure(order)

            end



          else


            if order_payment_intent.status == 'succeeded'


              ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
                  accept_order_request_success: true
              }

              driver_accept_order_success(driver, order, driver_payment_intent.id)


            else

              ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
                  accept_order_request_success: false,
                  message: 'Order has been canceled.'
              }


              Stripe::PaymentIntent.cancel(driver_payment_intent.id)


              driver_accept_order_failure(order)


            end



          end

        end

      end


    end

  end





  events.subscribe 'setup_intent.succeeded' do |event|

    include PaymentsHelper

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

        delete_other_existing_cards(stripe_customer_token, payment_method.id)

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