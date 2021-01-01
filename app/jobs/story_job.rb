class StoryJob < Struct.new(:post_id, :user_id)

  include PostCaseHelper

  def perform

    story_post = Post.find_by(id: post_id, is_story: true)

    if story_post != nil

      destroy_post_case(story_post)

      story_post.destroy!

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