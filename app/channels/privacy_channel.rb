class PrivacyChannel < ApplicationCable::Channel

  def subscribed

    if current_user.blank? || profile.blank?
      reject
    else

      user = profile.user

      if user.customer_user?

        stream_from "privacy_channel_#{profile.id}"

      else

        reject

      end

    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end