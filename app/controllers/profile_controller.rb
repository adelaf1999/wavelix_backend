class ProfileController < ApplicationController

  before_action :authenticate_user!

  def view_my_profile

    if current_user.store_user?

      @profile_data = {}

      # store specific profile data
      store_user = StoreUser.find_by(store_id: current_user.id)
      @profile_data[:store_name] = store_user.store_name
      @profile_data[:store_address] = store_user.store_address
      @profile_data[:store_number] = store_user.store_number

      # common profile data
      profile = current_user.profile
      @profile_data[:profile] = get_profile(profile)
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

  def get_profile(profile)

    profile_hash = eval(profile.to_json)
    posts = []

    profile.posts.each do |post|
      posts.push(post)
    end

    profile_hash[:posts] = posts

    profile_hash


  end




end
