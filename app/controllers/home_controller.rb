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

        profile_posts = Post.where(profile_id: profile_ids, is_story: false).order(created_at: :desc)

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

    @stories = get_user_stories(current_user)


    profile_ids = []

    current_user.active_followings.each do |followed_user|

      profile_ids.push(followed_user.profile.id)

    end



    # All Profile Posts

    profile_posts = Post.where(profile_id: profile_ids, is_story: false).order(created_at: :desc)

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

    @profile_blocked = current_user.profile.blocked?

    @report_types = PostReport.report_types


  end



end
