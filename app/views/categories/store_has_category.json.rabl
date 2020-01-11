if @success != nil
	node(:success) { @success }
end

if @has_subcategories != nil
    node(:has_subcategories) { @has_subcategories }
end