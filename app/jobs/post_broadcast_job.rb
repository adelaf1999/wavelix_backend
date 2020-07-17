class PostBroadcastJob < ApplicationJob

  queue_as :post_broadcast_queue

  def perform(user_id)


    user = User.find_by(id: user_id)

    profile = user.profile

    posts = []

    profile.posts.order(created_at: :desc).each do |post|
      posts.push(post.get_attributes)
    end

    @posts = posts.to_json

    ActionCable.server.broadcast "post_channel_#{user_id}", {posts: @posts}

    ActionCable.server.broadcast "profile_channel_#{profile.id}", {posts: @posts}



  end

end
