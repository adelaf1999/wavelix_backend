class CartChannel < ApplicationCable::Channel


  def start_stream(current_user)

    if current_user.customer_user?

      cart_id = params[:cart_id]

      if !cart_id.blank?

        customer_user  = CustomerUser.find_by(customer_id: current_user.id)

        cart = Cart.find_by(id: cart_id)

        if cart != nil

          if cart.id == customer_user.cart.id

            stream_from "cart_#{cart.id}_user_#{current_user.id}_channel"

          else

            reject

          end

        else

          reject

        end

      else

        reject

      end


    else

      reject


    end

  end


  def subscribed

    if current_user.blank?

      access_token = params[:access_token]

      client = params[:client]

      uid = params[:uid]

      user = User.find_by_uid(uid)

      if user != nil && user.valid_token?(access_token, client)

        start_stream(user)

      else

        reject

      end


    else

      start_stream(current_user)


    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end