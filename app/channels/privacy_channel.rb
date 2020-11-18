class PrivacyChannel < ApplicationCable::Channel

  def start_stream

    profile = Profile.find_by(id: params[:profile_id])

    if profile != nil

      user = profile.user

      if user.customer_user?

        stream_from "privacy_channel_#{profile.id}"

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

        start_stream

      else

        reject

      end

    else
      
      start_stream


    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end