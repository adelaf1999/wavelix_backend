module ProfileHelper

  def get_profile(profile)

    profile_hash = eval(profile.to_json)
    posts = []

    profile.posts.each do |post|
      posts.push(post)
    end

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