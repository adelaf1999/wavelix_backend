if @success != nil
    node(:success) { @success }
end

if @profile_data != nil
    node(:profile_data) { @profile_data }
end

if @current_store_unverified != nil
    node(:current_store_unverified) {  @current_store_unverified  }
end