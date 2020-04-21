class ProfileChannel < ApplicationCable::Channel

  def subscribed

    if current_user.blank? || profile.blank?
      reject
    else

      user = profile.user

      is_following = current_user.following?(user)

      is_private = profile.private_account?

      if user.customer_user?

        if !is_private || (is_private && is_following)

          stream_from "profile_channel_#{profile.id}"

        end

      else

        store_user = StoreUser.find_by(store_id: user.id)

        if store_user.verified?

          stream_from "profile_channel_#{profile.id}"

        end


      end

    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end