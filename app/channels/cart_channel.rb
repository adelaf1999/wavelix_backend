class CartChannel < ApplicationCable::Channel

  def subscribed

    if current_user.blank? || cart.blank?

      reject

    else

      if current_user.customer_user?

        customer_user = CustomerUser.find_by(customer_id: current_user.id)

        if customer_user.cart.id == cart.id

          stream_from "cart_#{cart.id}_customer_#{current_user.id}"

        else

          reject

        end

      else

        reject

      end


    end


  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end