if @success != nil
    node(:success) { @success  }
end

if @delivery_options != nil
    node(:delivery_options) { @delivery_options }
end

if @message != nil
    node(:message) { @message }
end

if @delivery_fee != nil
    node(:delivery_fee) { @delivery_fee }
end

if @can_order != nil
    node(:can_order) { @can_order }
end