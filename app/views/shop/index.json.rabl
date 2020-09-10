if @success != nil
    node(:success) { @success }
end

if @store_name != nil
    node(:store_name) { @store_name }
end

if @categories != nil
    node(:categories) { @categories }
end