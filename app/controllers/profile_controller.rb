class ProfileController < ApplicationController
  include ProfileHelper

  before_action :authenticate_user!

  def view_my_profile

    @profile_data = {}


    if current_user.store_user?
      # store specific profile data
      store_user = StoreUser.find_by(store_id: current_user.id)
      @profile_data[:store_name] = store_user.store_name
      @profile_data[:store_address] = store_user.store_address
      @profile_data[:store_number] = store_user.store_number
      @profile_data[:isVerified] = store_user.verified?
    end

    # common profile data
    profile = current_user.profile

    @profile_data[:profile] = get_profile(profile)

    @profile_data[:follow_relationships] = get_follow_relationships

    @profile_data = @profile_data.to_json # at end convert to json


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

  def search_follow

    search_follow_type = params[:search_follow_type]

    search = params[:search]

    if search_follow_type != nil && search != nil

      search_follow_type = search_follow_type.to_i


      if search_follow_type == 0

        follows_list = current_user.followers.merge(current_user.follower_relationships.where(status: 1))

      else

        follows_list = current_user.following.merge(current_user.following_relationships.where(status: 1))

      end

      search_by_username = follows_list.where("username ILIKE ?", "%#{search}%")

      new_follows_list = []

      new_follows_list = new_follows_list + search_by_username.uniq

      people = follows_list.where(user_type: 0)

      people_ids = []

      people.each do |person|
        people_ids.push(person.id)
      end

      people = CustomerUser.where(customer_id: people_ids)

      search_by_full_name =  people.where("full_name ILIKE ?", "%#{search}%")

      search_by_full_name.each do |customer_user|

        new_follows_list.push(User.find_by(id: customer_user.customer_id))

      end

      new_follows_list = new_follows_list.uniq

      stores = follows_list.where(user_type: 1)

      store_ids = []

      stores.each do |store|

        store_ids.push(store.id)

      end

      stores = StoreUser.where(store_id: store_ids)

      search_by_store_name = stores.where("store_name ILIKE ?", "%#{search}%")

      search_by_store_name.each do |store_user|

        new_follows_list.push(User.find_by(id: store_user.store_id))

      end

      new_follows_list = new_follows_list.uniq

      @search_results = []

      new_follows_list.each do |item|

        username = item.username
        profile_picture_url = item.profile.profile_picture.url
        @search_results.push({username: username, profile_picture_url: profile_picture_url})

      end

      @search_results = @search_results.to_json


    end


  end

  def change_profile_settings

    privacy_on = params[:privacy_on]

    profile = current_user.profile

    if privacy_on != nil && current_user.customer_user?

      privacy_on = eval(privacy_on.downcase)

      if privacy_on

        profile.privacy = 1

      else

        profile.privacy = 0

      end

    end

    profile.save!



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
