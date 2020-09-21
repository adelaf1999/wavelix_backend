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