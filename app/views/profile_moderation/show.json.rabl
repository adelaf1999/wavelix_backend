if @success != nil
    node(:success) { @success }
end

if @profile_picture != nil
    node(:profile_picture) { @profile_picture }
end

if @username != nil
    node(:username) { @username }
end

if @email != nil
    node(:email) { @email }
end

if @user_type != nil
    node(:user_type) { @user_type }
end

if @status != nil
    node(:status) { @status }
end

if @blocked_by != nil
    node(:blocked_by) { @blocked_by }
end

if @profile_bio != nil
    node(:profile_bio) { @profile_bio }
end

if @story_posts != nil
    node(:story_posts) { @story_posts }
end

if @profile_posts != nil
    node(:profile_posts) { @profile_posts }
end

if @admins_requested_block != nil
    node(:admins_requested_block) { @admins_requested_block }
end

if @blocked_reasons != nil
    node(:blocked_reasons) { @blocked_reasons }
end

if @block_requests != nil
    node(:block_requests) { @block_requests }
end


