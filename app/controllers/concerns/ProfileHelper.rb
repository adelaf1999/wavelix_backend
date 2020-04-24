module ProfileHelper

  def get_user_follow_requests(user)

    follow_requests = []

    user.follow_requests.each do |request|

      follower = User.find_by(id: request.follower_id)

      follow_requests.push({
                               username: follower.username,
                               profile_picture: follower.profile.profile_picture.url,
                               request_id: request.id
                           })

    end

    follow_requests

  end


  def get_follow_relationships(user)

    follow = {}

    following = []

    followers = []

    user.following_relationships.each do |following_relationship|

      if following_relationship.active?

        # get the following user name and profile picture (if they have one)

        followed_user = User.find_by(id: following_relationship.followed_id)
        username = followed_user.username
        profile_picture_url = followed_user.profile.profile_picture.url
        following.push({username: username, profile_picture_url: profile_picture_url})

      end

    end

    user.follower_relationships.each do |follower_relationship|

      if follower_relationship.active?

        follower_user = User.find_by(id: follower_relationship.follower_id)
        username = follower_user.username
        profile_picture_url = follower_user.profile.profile_picture.url
        followers.push({username: username, profile_picture_url: profile_picture_url})

      end

    end

    follow[:following] = following
    follow[:followers] = followers


    follow



  end

  def get_profile(profile)

    posts = []

    profile.posts.each do |post|
      posts.push(post)
    end

    profile = profile.to_json

    profile_hash = JSON.parse(profile)

    profile_hash[:posts] = posts

    profile_hash


  end

  def get_posts(profile)

    posts = []

    profile.posts.each do |post|
      posts.push(post)
    end

    posts

  end

end