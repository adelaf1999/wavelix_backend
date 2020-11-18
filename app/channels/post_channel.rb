class PostChannel < ApplicationCable::Channel


  def start_stream(current_user)

    stream_from "post_channel_#{current_user.id}"

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

