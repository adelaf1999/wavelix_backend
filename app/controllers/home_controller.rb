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

    # All Profile Posts

    current_user.following.each do |followed_user|

      profile_ids.push(followed_user.profile.id)

    end

    profile_posts = Post.where(status: 1, profile_id: profile_ids, is_story: false).order(created_at: :desc)


    profile_posts.each do |profile_post|

      @profile_posts.push(profile_post.get_attributes)

    end


  end







end
