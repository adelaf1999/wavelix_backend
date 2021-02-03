if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @message != nil
    node(:message) { @message }
end

if @redirect_url != nil
    node(:redirect_url) { @redirect_url }
end