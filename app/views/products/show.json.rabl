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