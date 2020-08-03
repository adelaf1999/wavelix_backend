if @success != nil
	node(:success) { @success }
end

if @has_subcategories != nil
    node(:has_subcategories) { @has_subcategories }
end

if @minimum_product_price != nil
    node(:minimum_product_price) { @minimum_product_price }
end