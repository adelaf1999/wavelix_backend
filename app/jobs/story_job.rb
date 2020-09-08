class StoryJob < Struct.new(:post_id, :user_id)

  def perform

    story_post = Post.find_by(id: post_id, is_story: true)

    if story_post != nil


      story_post.destroy

      user = User.find_by(id: user_id)

      profile = user.profile

      posts = []

      profile.posts.order(created_at: :desc).each do |post|

        posts.push(post.get_attributes)

      end

      @posts = posts.to_json

      ActionCable.server.broadcast "post_channel_#{user_id}", {posts: @posts}


    end



  end

end