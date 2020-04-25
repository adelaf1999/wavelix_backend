if @follow_requests != nil
    node(:follow_requests) { @follow_requests }
end

if @follow_relationships != nil
    node(:follow_relationships) { @follow_relationships }
end