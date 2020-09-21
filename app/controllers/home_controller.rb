class HomeController < ApplicationController

  include ValidationsHelper

  before_action :authenticate_user!


  def get_profile_posts

    @profile_posts = []

    post_category = params[:post_category]

    if !post_category.blank? && is_whole_number?(post_category)

      post_category = post_category.to_i

      if is_post_category_valid?(post_category)

        @success = true

        profile_ids = []

        if post_category == 0

          # All Profile Posts

          current_user.following.each do |followed_user|

            profile_ids.push(followed_user.profile.id)

          end

        elsif post_category == 1

          # Stores Posts

          current_user.following.where(user_type: 1).each do |followed_store|

            profile_ids.push(followed_store.profile.id)

          end

        else

          # Friends Posts

          current_user.following.where(user_type: 0).each do |followed_friend|

            profile_ids.push(followed_friend.profile.id)

          end


        end


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


  private


  def is_post_category_valid?(post_category)

    [0, 1, 2].include?(post_category)


  end


end
