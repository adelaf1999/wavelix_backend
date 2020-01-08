if @success != nil
    node(:success) {  @success }
end

if @message != nil
    node(:message) { @message }
end

if @products != nil
    node(:products) { @products }
end