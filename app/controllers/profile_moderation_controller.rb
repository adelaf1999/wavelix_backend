class ProfileModerationController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_admin!

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :profile_manager)

      head :unauthorized

    else

      @profiles = []

      limit = params[:limit]

      if is_positive_integer?(limit)

        profiles = Profile.all.order(created_at: :desc).limit(limit)

        profiles.each do |profile|

          @profiles.push(get_profile(profile))

        end

      end

    end


  end

  private

  def get_profile(profile)

    {
        username: profile.get_username,
        email: profile.get_email,
        user_type: profile.get_user_type,
        status: profile.status,
        profile_picture: profile.profile_picture.url,
        id: profile.id
    }

  end

end
