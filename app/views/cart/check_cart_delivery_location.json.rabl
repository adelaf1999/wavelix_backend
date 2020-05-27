if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @message != nil
    node(:message) { @message }
end

if @outside_zone_items != nil
    node(:outside_zone_items) { @outside_zone_items }
end

if @delivery_options != nil
    node(:delivery_options) { @delivery_options }
end