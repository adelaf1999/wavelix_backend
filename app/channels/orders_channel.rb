class OrdersChannel < ApplicationCable::Channel


  def subscribed

    if current_user.blank?

      reject

    else

      if current_user.store_user?

        stream_from "store_orders_channel_#{current_user.id}"

      elsif current_user.customer_user?

        stream_from "customer_orders_channel_#{current_user.id}"

      else

        reject

      end

    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end


end