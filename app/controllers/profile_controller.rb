class ProfileController < ApplicationController
  include ProfileHelper

  before_action :authenticate_user!

  def view_my_profile

    if current_user.store_user?

      @profile_data = {}

      # store specific profile data
      store_user = StoreUser.find_by(store_id: current_user.id)
      @profile_data[:store_name] = store_user.store_name
      @profile_data[:store_address] = store_user.store_address
      @profile_data[:store_number] = store_user.store_number
      @profile_data[:isVerified] = store_user.verified?

      # common profile data
      profile = current_user.profile
      @profile_data[:profile] = get_profile(profile)
      @profile_data[:follow_relationships] = get_follow_relationships
      @profile_data = @profile_data.to_json



    else

    end


  end

  def update_profile

    profile_picture = params[:profile_picture]

    profile_bio = params[:profile_bio]

    profile = current_user.profile

    if profile_picture != nil && profile_picture.is_a?(ActionDispatch::Http::UploadedFile) && is_picture_valid?(profile_picture)
      profile.profile_picture = profile_picture
    end


    if profile_bio != nil

      if profile_bio.empty?

        profile.profile_bio = profile_bio

      else

        profile_bio = profile_bio.strip

        num_bio_chars = profile_bio.chars.size

        if num_bio_chars <= 250
          profile.profile_bio = profile_bio
        end

      end

    end

    profile.save!

    @updated_profile = get_profile(profile).to_json


  end

  #def change_profile_settings
  #
  #end

  private

  def is_picture_valid?(picture)

    filename = picture.original_filename.split(".")
    extension = filename[filename.length - 1]
    valid_extensions = ["png" , "jpeg", "jpg", "gif"]
    valid_extensions.include?(extension)

  end

  def get_follow_relationships

    follow = {}

    following = []

    followers = []

    current_user.following_relationships.each do |following_relationship|

      if following_relationship.active?

        # get the following user name and profile picture (if they have one)

        followed_user = User.find_by(id: following_relationship.followed_id)
        username = followed_user.username
        profile_picture_url = followed_user.profile.profile_picture.url
        following.push({username: username, profile_picture_url: profile_picture_url})

      end

    end

    current_user.follower_relationships.each do |follower_relationship|

      if follower_relationship.active?

        follower_user = User.find_by(id: follower_relationship.follower_id)
        username = follower_user.username
        profile_picture_url = follower_user.profile.profile_picture.url
        followers.push({username: username, profile_picture_url: profile_picture_url})

      end

    end

    follow[:following] = following
    follow[:followers] = followers


    follow



  end




end
