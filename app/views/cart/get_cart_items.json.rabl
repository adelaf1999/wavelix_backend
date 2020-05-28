if @cart_items != nil
    node(:cart_items) { @cart_items }
end

if @home_address != nil
    node(:home_address) { @home_address }
end