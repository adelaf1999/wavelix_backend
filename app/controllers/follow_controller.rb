class FollowController < ApplicationController

  include ProfileHelper

  before_action :authenticate_user!

  def follow

    profile = Profile.find_by(id: params[:profile_id])

    if profile != nil

      user = profile.user

      @success = current_user.follow(user)

      if @success

        is_public = profile.public_account?

        if is_public

          @follow_relationships = get_follow_relationships(user)

        end



      end

    else

      @success = false

    end

  end

  def unfollow

    profile = Profile.find_by(id: params[:profile_id])

    if profile != nil

      user = profile.user

      @success = current_user.unfollow(user)

    else

      @success = false

    end

  end




end
