class HomeController < ApplicationController

  include ValidationsHelper

  include HomeHelper

  before_action :authenticate_user!


  def get_profile_posts

    @profile_posts = []

    post_category = params[:post_category]

    if !post_category.blank? && is_whole_number?(post_category)

      post_category = post_category.to_i

      if is_post_category_valid?(post_category)

        @success = true

        profile_ids = get_posts_profile_ids(post_category, current_user)

        profile_posts = Post.where(status: 1, profile_id: profile_ids, is_story: false).order(created_at: :desc)

        profile_posts.each do |profile_post|

          @profile_posts.push(profile_post.get_attributes)

        end



      else

        @success = false

      end

    else

      @success = false

    end



  end

  def index

    @profile_posts = []

    profile_ids = []

    @stories = get_user_stories(current_user)


    current_user.following.each do |followed_user|

      profile_ids.push(followed_user.profile.id)

    end



    # All Profile Posts

    profile_posts = Post.where(status: 1, profile_id: profile_ids, is_story: false).order(created_at: :desc)

    profile_posts.each do |profile_post|

      @profile_posts.push(profile_post.get_attributes)

    end



    # Get user country


    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      @user_country = store_user.store_country

    else

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      @user_country = customer_user.country


    end


  end



  private

  def get_user_stories(user)


    stories = []

    user.following.where(user_type: 1).each do |followed_store|


      story_posts = []

      followed_store.profile.posts.where(status: 1, is_story: true).each do |story_post|

        story_posts.push(story_post.get_attributes)

      end

      stories.push({
                        username: followed_store.username,
                        profile_picture: followed_store.profile.profile_picture.url,
                        posts: story_posts,
                        profile_id: followed_store.profile.id
                    })


    end


    user.following.where(user_type: 0).each do |followed_friend|


      story_posts = []

      followed_friend.profile.posts.where(status: 1, is_story: true).each do |story_post|

        story_posts.push(story_post.get_attributes)

      end

      stories.push({
                       username: followed_friend.username,
                       profile_picture: followed_friend.profile.profile_picture.url,
                       posts: story_posts,
                       profile_id: followed_friend.profile.id
                   })


    end


    stories


  end







end
