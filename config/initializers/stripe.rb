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

    order_request = OrderRequest.find_by(id: event.data.object.metadata.order_request_id)

    customer_user = CustomerUser.find_by(stripe_customer_token: event.data.object.customer)

    payment_intent_id = event.data.object.id
    
    if order_request != nil && customer_user != nil

      if OrderRequest.create_order(order_request, payment_intent_id)

        ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {payment_intent_success: true}

      end



    end


  end





  events.subscribe 'setup_intent.succeeded' do |event|

    customer_user = CustomerUser.find_by(stripe_customer_token: event.data.object.customer)

    if customer_user != nil

      # sanity check

      ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {setup_intent_success: true}

    end


  end


  events.subscribe 'setup_intent.setup_failed' do |event|

    customer_user = CustomerUser.find_by(stripe_customer_token: event.data.object.customer)

    if customer_user != nil

      # sanity check

      ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {setup_intent_success: false}

    end


  end




end