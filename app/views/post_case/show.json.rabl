if @success != nil
    node(:success) { @success }
end

if @post != nil
    node(:post) { @post }
end

if @post_author_username != nil
    node(:post_author_username) { @post_author_username }
end

if @post_author_profile_id != nil
    node(:post_author_profile_id) { @post_author_profile_id }
end

if @review_status != nil
    node(:review_status) { @review_status }
end

if @deleted_by != nil
    node(:deleted_by) {  @deleted_by }
end

if @post_complaints != nil
    node(:post_complaints) { @post_complaints }
end

if @admins_reviewed != nil
    node(:admins_reviewed) { @admins_reviewed }
end

if @reviewed_by != nil
    node(:reviewed_by) { @reviewed_by }
end