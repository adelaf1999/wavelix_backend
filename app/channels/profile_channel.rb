class ProfileChannel < ApplicationCable::Channel


  def start_stream(current_user)

    profile = Profile.find_by(id: params[:profile_id])

    if profile != nil

      user = profile.user

      is_following = current_user.following?(user)

      is_private = profile.private_account?

      if user.customer_user?

        if !is_private || (is_private && is_following)

          stream_from "profile_channel_#{profile.id}"

        else

          reject

        end

      else

        store_user = StoreUser.find_by(store_id: user.id)

        if store_user.verified?

          stream_from "profile_channel_#{profile.id}"

        else

          reject

        end


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