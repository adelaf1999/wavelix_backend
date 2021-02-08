if @success != nil
    node(:success) { @success }
end

if @driver_name != nil
    node(:driver_name) { @driver_name }
end

if @driver_phone_number != nil
    node(:driver_phone_number) { @driver_phone_number }
end

if @driver_country != nil
    node(:driver_country) { @driver_country }
end

if @driver_account_status != nil
    node(:driver_account_status) { @driver_account_status }
end

if @driver_balance_usd != nil
    node(:driver_balance_usd) { @driver_balance_usd }
end

if @driver_latitude != nil
    node(:driver_latitude) { @driver_latitude }
end

if @driver_longitude != nil
    node(:driver_longitude) { @driver_longitude }
end

if @unsuccessful_orders != nil
    node(:unsuccessful_orders) { @unsuccessful_orders }
end