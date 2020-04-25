class FollowController < ApplicationController

  include ProfileHelper

  before_action :authenticate_user!

  def set_follow_request_status


    follow_request = current_user.follow_requests.find_by(id: params[:request_id])

    status = params[:status]

    if follow_request != nil && status != nil

      if is_positive_integer?(status)

        status = status.to_i

        if status == 0

          follow_request.destroy!

          @follow_requests = get_user_follow_requests(current_user)

          @follow_relationships = get_follow_relationships(current_user)

        elsif status == 1

          follow_request.active!

          @follow_requests = get_user_follow_requests(current_user)

          @follow_relationships = get_follow_relationships(current_user)


        end



      end



    end


  end

  def cancel_follow_request

    profile = Profile.find_by(id: params[:profile_id])

    if profile != nil

      user = profile.user

      follower_relationship = user.follower_relationships.find_by(follower_id: current_user.id)

      if follower_relationship != nil

        if follower_relationship.inactive?

          follower_relationship.destroy!

          @success = true

        else

          @success = false

        end



      else

        @success = false

      end

    else

      @success = false


    end

  end

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

  private


  def is_positive_integer?(arg)

    res = /^(?<num>\d+)$/.match(arg)

    if res == nil
      false
    else
      true
    end

  end




end
