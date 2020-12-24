class ProfileModerationChannel < ApplicationCable::Channel

  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    profile_id = params[:profile_id]

    admin = Admin.find_by_uid(uid)

    profile = Profile.find_by(id: profile_id)

    if admin != nil && admin.valid_token?(access_token, client) && profile != nil

      if admin.has_roles?(:root_admin, :profile_manager)

        stream_from "profile_moderation_channel_#{profile.id}"

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