if @success != nil
    node(:success) { @success }
end

if @product != nil
    node(:product) { @product }
end

if @product_pictures != nil
    node(:product_pictures) { @product_pictures }
end

if @minimum_product_price != nil
    node(:minimum_product_price) { @minimum_product_price }
end