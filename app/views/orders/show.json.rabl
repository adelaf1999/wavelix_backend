if @success != nil
    node(:success) { @success }
end

if @products != nil
    node(:products) { @products }
end

if @driver_id != nil
    node(:driver_id) {  @driver_id }
end

if @driver_name != nil
    node(:driver_name) { @driver_name }
end

if @status != nil
    node(:status) { @status }
end

if @delivery_location != nil
    node(:delivery_location) { @delivery_location }
end

if @ordered_at != nil
    node(:ordered_at) { @ordered_at }
end

if @store_user_id != nil
    node(:store_user_id) { @store_user_id }
end

if @store_name != nil
    node(:store_name) { @store_name }
end

if @customer_user_id != nil
    node(:customer_user_id) { @customer_user_id }
end

if @customer_name != nil
   node(:customer_name) {  @customer_name }
end

if @country != nil
    node(:country) { @country }
end

if @delivery_fee != nil
    node(:delivery_fee) { @delivery_fee }
end

if @delivery_fee_currency != nil
    node(:delivery_fee_currency) { @delivery_fee_currency }
end

if @order_type != nil
    node(:order_type) { @order_type }
end

if @store_confirmation_status != nil
    node(:store_confirmation_status) { @store_confirmation_status }
end

if @store_handles_delivery != nil
    node(:store_handles_delivery) { @store_handles_delivery }
end

if @customer_canceled_order != nil
    node(:customer_canceled_order) { @customer_canceled_order }
end

if @order_canceled_reason != nil
    node(:order_canceled_reason) { @order_canceled_reason }
end

if @store_fulfilled_order != nil
    node(:store_fulfilled_order) { @store_fulfilled_order }
end

if @driver_fulfilled_order != nil
    node(:driver_fulfilled_order) { @driver_fulfilled_order }
end

if @total_price != nil
    node(:total_price) { @total_price }
end

if @total_price_currency != nil
    node(:total_price_currency) { @total_price_currency }
end

if @delivery_time_limit != nil
    node(:delivery_time_limit) { @delivery_time_limit }
end

if @store_arrival_time_limit != nil
    node(:store_arrival_time_limit) { @store_arrival_time_limit }
end

if @receipt_url != nil
    node(:receipt_url) { @receipt_url }
end

if @confirmed_by != nil
    node(:confirmed_by) { @confirmed_by }
end

if @canceled_by != nil
    node(:canceled_by) { @canceled_by }
end

if @resolve_time_limit != nil
    node(:resolve_time_limit) { @resolve_time_limit }
end

if @store_payments != nil
    node(:store_payments) { @store_payments }
end

if @driver_payments != nil
    node(:driver_payments) { @driver_payments }
end