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

      if @success

        is_public = profile.public_account?

        if is_public

          @follow_relationships = get_follow_relationships(user)

        else

          @profile_data = {}

          username = user.username
          profile_picture = profile.profile_picture.url
          profile_bio = profile.profile_bio

          @profile_data[:is_following] = false
          @profile_data[:user_type] = user.user_type
          @profile_data[:username] = username
          @profile_data[:profile_picture] = profile_picture
          @profile_data[:profile_bio] = profile_bio
          @profile_data[:is_private] = true

          follow_relationships = get_follow_relationships(user)

          followers = follow_relationships[:followers]

          following = follow_relationships[:following]

          placeholder_followers = []

          placeholder_following = []

          for i in 1..followers.count do

            placeholder_followers.push("placeholder#{i}")

          end

          for i in 1..following.count do

            placeholder_following.push("placeholder#{i}")

          end

          follow_relationships[:followers] = placeholder_followers

          follow_relationships[:following] = placeholder_following

          @profile_data[:follow_relationships] = follow_relationships

        end


      end

    else

      @success = false

    end

  end




end
