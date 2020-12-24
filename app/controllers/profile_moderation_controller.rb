class ProfileModerationController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_admin!


  def request_store_profile_block

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:profile_manager)

      head :unauthorized

    else

      profile = Profile.find_by(id: params[:profile_id])

      reason = params[:reason]

      if profile != nil && !reason.blank?

        user = profile.user

        if user.store_user? && profile.unblocked?

          admins_requested_block = profile.get_admins_requested_block

          if admins_requested_block.include?(current_admin.id)

            @success = false

          else

            @success = true

            admins_requested_block.push(current_admin.id)

            profile.update!(admins_requested_block: admins_requested_block)

            BlockRequest.create!(admin_name: current_admin.full_name, reason: reason, profile_id: profile.id)

            ActionCable.server.broadcast "profile_moderation_channel_#{profile.id}", {
                admins_requested_block: admins_requested_block,
                block_requests: profile.get_block_requests
            }


            admins = Admin.role_root_admins

            admins.each do |admin|

              AdminAccountMailer.delay.store_profile_block_request(admin.email, profile.id)

            end


          end


        else

          @success = false

        end


      else

        @success = false

      end



    end


  end

  def block_customer_profile

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :profile_manager)

      head :unauthorized

    else

      profile = Profile.find_by(id: params[:profile_id])

      reason = params[:reason]

      if profile != nil && !reason.blank?

        user = profile.user

        if user.customer_user? && profile.unblocked?

          @success = true

          profile.blocked!

          admin_name = current_admin.full_name

          profile.update!(blocked_by: admin_name)

          BlockedReason.create!(admin_name: admin_name, reason: reason, profile_id: profile.id)

          ActionCable.server.broadcast "profile_moderation_channel_#{profile.id}", {
              status: profile.status,
              blocked_by: profile.blocked_by,
              blocked_reasons: profile.get_blocked_reasons
          }

          profile.posts.destroy_all

          user.comments.destroy_all

          user.likes.destroy_all


        else

          @success = false

        end


      else

        @success = false

      end

    end


  end

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

        @blocked_reasons = profile.get_blocked_reasons

        @block_requests = profile.get_block_requests


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
