class DriverChannel < ApplicationCable::Channel

  def subscribed

    if current_user.blank?

      reject

    else

      if current_user.customer_user?

        customer_user = CustomerUser.find_by(customer_id: current_user.id)

        stream_from "driver_channel_#{customer_user.id}"

      else

        reject

      end

    end

  end


  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end