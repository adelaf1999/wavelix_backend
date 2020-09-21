if @profile_posts != nil
    node(:profile_posts) { @profile_posts }
end

if @user_country != nil
    node(:user_country) { @user_country }
end