class HomeController < ApplicationController

  before_action :authenticate_user!

  def index


    stores_profile_ids = []

    friends_profile_ids = []



    current_user.following.each do |followed_user|

      if followed_user.customer_user?

        friends_profile_ids.push(followed_user.profile.id)

      else

        stores_profile_ids.push(followed_user.profile.id)

      end



    end



    @stores_posts = []

    @friends_posts = []
    

    stores_posts = Post.where(status: 1, profile_id: stores_profile_ids).order(created_at: :desc)

    stores_posts = stores_posts.uniq { |store_post| store_post.profile_id }.first(10)


    friends_posts = Post.where(status: 1, profile_id: friends_profile_ids).order(created_at: :desc)

    friends_posts = friends_posts.uniq { |friend_post| friend_post.profile_id }.first(10)


    stores_posts.each do |store_post|

      @stores_posts.push(store_post.get_attributes)

    end


    friends_posts.each do |friend_post|

      @friends_posts.push(friend_post.get_attributes)

    end









  end

end
