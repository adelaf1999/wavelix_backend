module PostHelper


  def send_my_posts

    profile = current_user.profile

    posts = []

    profile.posts.each do |p|
      posts.push(p.get_attributes)
    end

    @posts = posts.to_json


    ActionCable.server.broadcast "post_channel_#{current_user.id}", {posts: @posts}

    ActionCable.server.broadcast "profile_channel_#{profile.id}", {posts: @posts}



  end

  def send_posts(current_user_profile, post_profile)

    if current_user_profile.id == post_profile.id

      posts = []

      current_user_profile.posts.each do |p|
        posts.push(p.get_attributes)
      end

      @posts = posts.to_json

      ActionCable.server.broadcast "post_channel_#{current_user.id}", {posts: @posts}

    else


      posts = []

      post_profile.posts.each do |p|
        posts.push(p.get_attributes)
      end

      @posts = posts.to_json

      ActionCable.server.broadcast "profile_channel_#{post_profile.id}", {posts: @posts}


    end

  end

end