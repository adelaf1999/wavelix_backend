class DriveSettingsChannel < ApplicationCable::Channel

  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    user = User.find_by_uid(uid)

    if user != nil &&  user.valid_token?(access_token, client)

      if user.customer_user?

        customer_user = CustomerUser.find_by(customer_id: user.id)

        stream_from "drive_settings_channel_#{customer_user.id}"

      else

        reject

      end

    else

      reject

    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end


end