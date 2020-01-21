if @success != nil
    node(:success) { @success }
end

if @message != nil
    node(:message) { @message }
end

if @posts != nil
    node(:posts) { @posts }
end