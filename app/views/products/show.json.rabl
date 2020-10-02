if @success != nil
    node(:success) { @success }
end

if @product_pictures != nil
    node(:product_pictures) { @product_pictures }
end

if @product != nil
    node(:product) { @product }
end

if @product_options != nil
    node(:product_options) { @product_options }
end

if @product_details != nil
    node(:product_details) { @product_details }
end


if @store != nil
    node(:store) { @store }
end

if @customer_country  != nil
    node(:customer_country) { @customer_country  }
end

if @home_address != nil
    node(:home_address) { @home_address }
end

if @product_currency != nil
    node(:product_currency) {  @product_currency }
end

if @product_price != nil
    node(:product_price) { @product_price }
end


if @has_sensitive_products != nil
    node(:has_sensitive_products) { @has_sensitive_products }
end

if @handles_delivery != nil
    node(:handles_delivery) { @handles_delivery }
end

if  @has_saved_card != nil
    node(:has_saved_card) {  @has_saved_card }
end

if @similar_items != nil
    node(:similar_items) { @similar_items }
end


node(:maximum_delivery_distance) { @maximum_delivery_distance }