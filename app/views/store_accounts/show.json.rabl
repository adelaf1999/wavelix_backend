if @success != nil
    node(:success) { @success }
end

if @store_owner != nil
    node(:store_owner) { @store_owner }
end

if @store_username != nil
    node(:store_username) { @store_username  }
end

if @store_name != nil
    node(:store_name) { @store_name }
end

if @status != nil
    node(:status) { @status }
end

if @review_status != nil
    node(:review_status) { @review_status }
end

if @country != nil
    node(:country) { @country }
end

if @has_sensitive_products != nil
    node(:has_sensitive_products) { @has_sensitive_products }
end

if @business_license != nil
    node(:business_license) { @business_license }
end

if @registered_at != nil
    node(:registered_at) { @registered_at }
end

if @location != nil
    node(:location) { @location }
end

if @store_owner_number != nil
    node(:store_owner_number) { @store_owner_number }
end

if @store_number != nil
    node(:store_number) { @store_number }
end

if @verified_by != nil
    node(:verified_by) { @verified_by }
end

if @declined_verification != nil
    node(:declined_verification) {  @declined_verification }
end