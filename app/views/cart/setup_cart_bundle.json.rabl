if @success != nil
    node(:success) { @success }
end

if @error_code != nil
   node(:error_code) {  @error_code }
end

if @cart_bundles != nil
    node(:cart_bundles) { @cart_bundles }
end