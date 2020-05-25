if @cart_bundles != nil
    node(:cart_bundles) { @cart_bundles }
end

if @home_address != nil
    node(:home_address) { @home_address }
end