if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @message != nil
    node(:message) { @message }
end

if @delivery_options != nil
    node(:delivery_options) { @delivery_options }
end

if @cart_bundles != nil
    node(:cart_bundles) { @cart_bundles }
end