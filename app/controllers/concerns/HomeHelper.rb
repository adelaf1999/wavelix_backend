module HomeHelper

  include ValidationsHelper


  def get_posts_profile_ids(post_category, user)

    profile_ids = []

    if post_category == 0

      # All Profile Posts

      user.following.each do |followed_user|

        profile_ids.push(followed_user.profile.id)

      end

    elsif post_category == 1

      # Stores Posts

      user.following.where(user_type: 1).each do |followed_store|

        profile_ids.push(followed_store.profile.id)

      end

    else

      # Friends Posts

      user.following.where(user_type: 0).each do |followed_friend|

        profile_ids.push(followed_friend.profile.id)

      end


    end

    profile_ids

  end


  def get_user_stories(user)


    stories = []

    user.active_followings.where(user_type: 1).each do |followed_store|


      story_posts = []

      followed_store.profile.posts.where(status: 1, is_story: true).order(created_at: :asc).each do |story_post|

        story_posts.push(story_post.get_attributes)

      end

      if story_posts.length > 0


        stories.push({
                         username: followed_store.username,
                         profile_picture: followed_store.profile.profile_picture.url,
                         posts: story_posts,
                         profile_id: followed_store.profile.id
                     })


      end



    end


    user.active_followings.where(user_type: 0).each do |followed_friend|


      story_posts = []

      followed_friend.profile.posts.where(status: 1, is_story: true).order(created_at: :asc).each do |story_post|

        story_posts.push(story_post.get_attributes)

      end


      if story_posts.length > 0

        stories.push({
                         username: followed_friend.username,
                         profile_picture: followed_friend.profile.profile_picture.url,
                         posts: story_posts,
                         profile_id: followed_friend.profile.id
                     })

      end




    end


    stories


  end

  def send_stories_to_home_page(user)

    stories = get_user_stories(user)

    ActionCable.server.broadcast "home_channel_#{user.id}", {stories: stories}

  end


 def send_profile_posts_home_page(post_category, user)

   if !post_category.blank? && is_whole_number?(post_category)

     post_category = post_category.to_i

     if is_post_category_valid?(post_category)

       profile_ids = get_posts_profile_ids(post_category, user)

       profile_posts = []

       Post.where(status: 1, profile_id: profile_ids, is_story: false).order(created_at: :desc).each do |profile_post|

         profile_posts.push(profile_post.get_attributes)

       end

       ActionCable.server.broadcast "home_channel_#{user.id}", {profile_posts: profile_posts}


     end

   end


 end


  def is_post_category_valid?(post_category)

    [0, 1, 2].include?(post_category)


  end

end