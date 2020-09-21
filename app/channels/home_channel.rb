class HomeChannel < ApplicationCable::Channel

  def subscribed

    if current_user.blank?

      reject

    else
      stream_from "home_channel_#{current_user.id}"

    end

  end
  

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end