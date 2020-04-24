if @success != nil
    node(:success) { @success }
end

if @follow_relationships != nil
    node(:follow_relationships) {  @follow_relationships }
end

if @profile_data != nil
    node(:profile_data) { @profile_data  }
end