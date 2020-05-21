if @success != nil
    node(:success) { @success  }
end

if @delivery_options != nil
    node(:delivery_options) { @delivery_options }
end

if @message != nil
    node(:message) { @message }
end