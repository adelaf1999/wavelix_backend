if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @redirect_url != nil
  node(:redirect_url) {  @redirect_url }
end


if @error_message != nil
    node(:error_message) { @error_message }
end

if @product != nil
    node(:product) { @product }
end

if @product_options != nil
    node(:product_options) { @product_options }
end

if @has_sensitive_products != nil
    node(:has_sensitive_products) { @has_sensitive_products }
end

if @handles_delivery != nil
    node(:handles_delivery) { @handles_delivery }
end

if @maximum_delivery_distance != nil
    node(:maximum_delivery_distance) { @maximum_delivery_distance }
end


