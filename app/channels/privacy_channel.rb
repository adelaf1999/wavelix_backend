class PrivacyChannel < ApplicationCable::Channel

  def subscribed

    if current_user.blank?

      reject

    else
      
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

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end