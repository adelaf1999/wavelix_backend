class StoryJob < Struct.new(:post_id, :user_id)

  def perform

    story_post = Post.find_by(id: post_id)

    if story_post.is_story

      story_post.destroy

      user = User.find_by(id: user_id)

      profile = user.profile

      posts = []

      profile.posts.each do |post|
        posts.push(post.get_attributes)
      end

      @posts = posts.to_json

      ActionCable.server.broadcast "post_channel_#{user_id}", {posts: @posts}


    end



  end

end