Stripe.api_key             = ENV.fetch('STRIPE_SECRET_KEY')
StripeEvent.signing_secret = ENV.fetch('STRIPE_SIGNING_SECRET')

StripeEvent.configure do |events|

  events.subscribe 'setup_intent.succeeded' do |event|

    customer_user = CustomerUser.find_by(stripe_customer_token: event.data.object.customer)

    if customer_user != nil

      # sanity check

      ActionCable.server.broadcast "view_product_#{customer_user.id}_channel", {setup_intent_success: true}

    end


  end



end