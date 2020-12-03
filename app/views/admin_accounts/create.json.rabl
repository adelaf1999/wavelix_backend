if @success != nil
    node(:success) { @success }
end

if @message != nil
    node(:message) { @message }
end

if @error_code != nil
    node(:error_code) { @error_code }
end