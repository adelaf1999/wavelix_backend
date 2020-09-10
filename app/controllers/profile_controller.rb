class ProfileController < ApplicationController
  include ProfileHelper

  before_action :authenticate_user!

  def view_user_profile

    # store user can only be viewed if verified

    # customer user can only be viewed if phone number is verified

    # customer user can be viewed based on privacy settings and on following status

    profile = Profile.find_by(id: params[:profile_id])

    if profile != nil && profile.id != current_user.profile.id

      user = profile.user

      following_relationship = current_user.following_relationships.find_by(followed_id: user.id)

      if following_relationship != nil

        if following_relationship.active?

          is_following = true

        else

          is_following = false

        end


      else

        is_following = false

      end

      if current_user.store_user?

        store_user = StoreUser.find_by(store_id: current_user.id)

        if store_user.unverified?

          @current_store_unverified = true

        end

      elsif current_user.customer_user?

        customer_user  = CustomerUser.find_by(customer_id: current_user.id)

        if !customer_user.phone_number_verified?

          @success = false

          return

        else

          @customer_country = customer_user.country

        end


      end



      is_private = profile.private_account?

      user_type = user.user_type

      if user.customer_user?

        customer_user = CustomerUser.find_by(customer_id: user.id)

        if customer_user.phone_number_verified?

          @profile_data = {}


          username = user.username
          profile_picture = profile.profile_picture.url
          profile_bio = profile.profile_bio


          # Common data when user profile is public/private
          @success = true
          cookies.encrypted[:profile_id] = profile.id

          @profile_data[:is_following] = is_following
          @profile_data[:user_type] = user_type
          @profile_data[:username] = username
          @profile_data[:profile_picture] = profile_picture
          @profile_data[:profile_bio] = profile_bio
          @profile_data[:is_private] = is_private

          if profile.public_account? || (profile.private_account? && is_following)


            profile_posts = get_complete_profile_posts(profile)
            story_posts = get_complete_story_posts(profile)
            follow_relationships = get_follow_relationships(user)

            @profile_data[:profile_posts] = profile_posts
            @profile_data[:story_posts] = story_posts
            @profile_data[:follow_relationships] = follow_relationships

          else

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

            follower_relationship = user.follower_relationships.find_by(follower_id: current_user.id)

            if follower_relationship != nil && follower_relationship.inactive?

              @profile_data[:is_requested] = true

            end

            @profile_data[:follow_relationships] = follow_relationships




          end

        else

          @success = false

        end


      else

        store_user = StoreUser.find_by(store_id: user.id)

        if store_user.verified?

          @profile_data = {}
          @success = true
          cookies.encrypted[:profile_id] = profile.id

          username = user.username
          follow_relationships = get_follow_relationships(user)
          profile_picture = profile.profile_picture.url
          profile_bio = profile.profile_bio
          profile_posts = get_complete_profile_posts(profile)
          story_posts = get_complete_story_posts(profile)
          store_name = store_user.store_name

          @profile_data[:is_following] = is_following
          @profile_data[:is_private] = is_private
          @profile_data[:user_type] = user_type
          @profile_data[:username] = username
          @profile_data[:profile_picture] = profile_picture
          @profile_data[:profile_bio] = profile_bio
          @profile_data[:profile_posts] = profile_posts
          @profile_data[:story_posts] = story_posts
          @profile_data[:follow_relationships] = follow_relationships
          @profile_data[:store_name] = store_name
          @profile_data[:store_user_id] = store_user.id




        else

          @success = false

        end


      end


    else

      @success = false

    end


  end

  def view_my_profile

    @profile_data = {}

    if current_user.store_user?

      # store specific profile data
      store_user = StoreUser.find_by(store_id: current_user.id)
      @profile_data[:store_name] = store_user.store_name
      @profile_data[:store_address] = store_user.store_address
      @profile_data[:store_number] = store_user.store_number
      @profile_data[:current_store_unverified] = store_user.unverified?

    else

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      else

        @profile_data[:follow_requests] = get_user_follow_requests(current_user)

      end



    end

    # common profile data
    profile = current_user.profile

    @profile_data[:profile] = get_profile(profile)

    @profile_data[:follow_relationships] = get_follow_relationships(current_user)

    @profile_data = @profile_data.to_json # at end convert to json


  end

  def update_profile

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

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


    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end


    search_follow_type = params[:search_follow_type]

    search = params[:search]

    profile_id = params[:profile_id]

    if search_follow_type != nil && search != nil

      search_follow_type = search_follow_type.to_i


      if profile_id != nil


        profile = Profile.find_by(id: profile_id)

        if profile != nil && current_user.profile.id != profile.id

          user = profile.user

          is_following = current_user.following?(user)

          if user.customer_user? && !is_following && profile.private_account?

            @success = false

            return

          elsif user.store_user?

            store_user = StoreUser.find_by(store_id: user.id)

            if store_user.unverified?

              @success = false

              return

            end

          end

        else

          @success = false

          return

        end


      end



      if search_follow_type == 0

        profile = Profile.find_by(id: profile_id)


        if profile != nil

          user = profile.user

          follows_list = user.followers.merge(user.follower_relationships.where(status: 1))

        else

          follows_list = current_user.followers.merge(current_user.follower_relationships.where(status: 1))

        end


      else

        profile = Profile.find_by(id: profile_id)

        if profile != nil

          user = profile.user

          follows_list = user.following.merge(user.following_relationships.where(status: 1))


        else

          follows_list = current_user.following.merge(current_user.following_relationships.where(status: 1))

        end


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

      @success = true


    end


  end

  def change_profile_settings

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

    privacy_on = params[:privacy_on]

    profile = current_user.profile

    if privacy_on != nil && current_user.customer_user?

      privacy_on = eval(privacy_on.downcase)

      was_private = profile.private_account?

      if privacy_on

        profile.privacy = 1

      else

        profile.privacy = 0

        if was_private

          # Profile was private and now its not so accept all follower requests automatically

          current_user.follower_relationships.each do |follower_relationship|

            follower_relationship.active!

          end

          @follow_relationships = get_follow_relationships(current_user)


        end


      end

      profile.save!

      ActionCable.server.broadcast "privacy_channel_#{profile.id}", {is_private: profile.private_account?}

    end





  end

  #def change_profile_settings
  #
  #end

  private


  def get_complete_story_posts(profile)

    story_posts = []

    profile.posts.order(created_at: :desc).each do |post|

      if post.complete? && post.is_story

        story_posts.push(post.get_attributes)

      end

    end

    story_posts.to_json

  end

  def get_complete_profile_posts(profile)

    profile_posts = []

    profile.posts.order(created_at: :desc).each do |post|

      if post.complete? && !post.is_story

        profile_posts.push(post.get_attributes)

      end

    end

    profile_posts.to_json

  end

  def is_picture_valid?(picture)

    filename = picture.original_filename.split(".")
    extension = filename[filename.length - 1]
    valid_extensions = ["png" , "jpeg", "jpg", "gif"]
    valid_extensions.include?(extension)

  end



end
