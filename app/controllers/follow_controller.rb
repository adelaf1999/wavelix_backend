class FollowController < ApplicationController

  before_action :authenticate_user!

  def follow

    profile = Profile.find_by(id: params[:profile_id])

    if profile != nil

      user = profile.user

      @success = current_user.follow(user)

    else

      @success = false

    end

  end




end
