module ProfileHelper

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