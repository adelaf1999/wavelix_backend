class HomeChannel < ApplicationCable::Channel


  def start_stream(user_id)

    stream_from "home_channel_#{user_id}"

  end

  def subscribed

    if current_user.blank?

      access_token = params[:access_token]

      client = params[:client]

      uid = params[:uid]

      user = User.find_by_uid(uid)

      if user != nil && user.valid_token?(access_token, client)

        start_stream(user.id)

      else

        reject

      end


    else

      start_stream(current_user.id)

    end

  end
  

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end