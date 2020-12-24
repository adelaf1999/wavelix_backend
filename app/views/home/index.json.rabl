if @user_country != nil
    node(:user_country) { @user_country }
end

if @stories != nil
    node(:stories) { @stories }
end

if @profile_posts != nil
    node(:profile_posts) { @profile_posts }
end

if @profile_blocked != nil
    node(:profile_blocked) { @profile_blocked }
end