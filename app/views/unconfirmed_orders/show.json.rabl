if @success != nil
    node(:success) { @success }
end

if @store_name != nil
    node(:store_name) { @store_name }
end

if @store_user_id != nil
    node(:store_user_id) { @store_user_id }
end

if @store_owner != nil
    node(:store_owner) { @store_owner }
end

if @store_owner_number != nil
    node(:store_owner_number) { @store_owner_number   }
end

if @store_number != nil
    node(:store_number) { @store_number }
end

if @store_has_sensitive_products != nil
    node(:store_has_sensitive_products) {  @store_has_sensitive_products }
end

if @customer_name != nil
    node(:customer_name) {  @customer_name }
end

if @customer_user_id != nil
    node(:customer_user_id)  { @customer_user_id }
end

if @customer_number != nil
    node(:customer_number) { @customer_number }
end

if @country != nil
    node(:country) { @country }
end

if @delivery_time_limit != nil
    node(:delivery_time_limit) { @delivery_time_limit }
end

if @ordered_at != nil
    node(:ordered_at) { @ordered_at }
end

if @total_price != nil
    node(:total_price) { @total_price }
end

if @total_price_currency != nil
    node(:total_price_currency) { @total_price_currency }
end

if @receipt_url != nil
    node(:receipt_url) { @receipt_url }
end

if @products != nil
    node(:products) { @products }
end

if @delivery_location != nil
    node(:delivery_location) { @delivery_location }
end