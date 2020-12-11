if @store_accounts != nil
    node(:store_accounts) { @store_accounts }
end

if @account_status_options != nil
    node(:account_status_options) { @account_status_options }
end

if @review_status_options != nil
    node(:review_status_options) { @review_status_options }
end

if @countries != nil
    node(:countries) { @countries }
end