class ProfileModerationController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_admin!



  def show

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :profile_manager)

      head :unauthorized

    else

      profile = Profile.find_by(id: params[:profile_id])

      if profile != nil

        @success = true

        @profile_picture = profile.profile_picture.url.blank? ? '' : profile.profile_picture.url

        @username = profile.get_username

        @email = profile.get_email

        @user_type = profile.get_user_type

        @status = profile.status

        @blocked_by = profile.blocked_by

        @profile_bio = profile.profile_bio.blank?  ? '' : profile.profile_bio

        @story_posts = get_story_posts(profile)

        @profile_posts = get_profile_posts(profile)

        @admins_requested_block = profile.get_admins_requested_block

        @blocked_reasons = []

        @block_requests = []


        profile.blocked_reasons.each do |blocked_reason|

          @blocked_reasons.push({
                                  admin_name: blocked_reason.admin_name,
                                  reason: blocked_reason.reason
                                })

        end

        profile.block_requests.each do |block_request|

          @block_requests.push({
                                   admin_name: block_request.admin_name,
                                   reason: block_request.reason
                               })

        end






      else

        @success = false

      end


    end


  end

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

  def get_story_posts(profile)

    story_posts = []

    profile.posts.order(created_at: :desc).each do |post|

      if post.complete? && post.is_story

        story_posts.push(post.get_attributes)

      end

    end

    story_posts

  end

  def get_profile_posts(profile)

    profile_posts = []

    profile.posts.order(created_at: :desc).each do |post|

      if post.complete? && !post.is_story

        profile_posts.push(post.get_attributes)

      end

    end

    profile_posts

  end

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
