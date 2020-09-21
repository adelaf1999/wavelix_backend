class HomeController < ApplicationController

  include ValidationsHelper

  before_action :authenticate_user!

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
