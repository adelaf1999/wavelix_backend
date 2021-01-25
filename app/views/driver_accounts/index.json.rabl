if @driver_accounts != nil
    node(:driver_accounts) { @driver_accounts }
end

if @review_status_options != nil
    node(:review_status_options) { @review_status_options }
end

if @countries != nil
    node(:countries) { @countries }
end

if @account_status_options != nil
    node(:account_status_options) { @account_status_options }
end