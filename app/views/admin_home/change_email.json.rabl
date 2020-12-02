if @success != nil
    node(:success) { @success }
end

if @message != nil
    node(:message) { @message }
end

if @email != nil
    node(:email) { @email }
end

if @uid != nil
    node(:uid) { @uid }
end