if @driver_accounts != nil
    node(:driver_accounts) { @driver_accounts }
end

if @verified_options != nil
    node(:verified_options) { @verified_options }
end

if @account_blocked_options != nil
    node(:account_blocked_options) { @account_blocked_options }
end

if @review_status_options != nil
    node(:review_status_options) { @review_status_options }
end

if @countries != nil
    node(:countries) { @countries }
end