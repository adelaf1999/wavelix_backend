class ProfileModerationController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_admin!


  def search_user_profiles

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :profile_manager)

      head :unauthorized

    else

      # search for user profiles by username or email

      @profiles = []

      search = params[:search]

      limit = params[:limit]

      if search != nil && is_positive_integer?(limit)

        search = search.strip

        users = User.all.where("username ILIKE ?", "%#{search}%").or( User.all.where("email ILIKE ?", "%#{search}%") ).limit(limit)

        user_ids = []

        users.each do |user|

          user_ids.push(user.id)

        end

        profiles = Profile.where(user_id: user_ids).order(created_at: :desc)

        profiles.each do |profile|

          @profiles.push(get_profile(profile))

        end




      end


    end


  end


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
