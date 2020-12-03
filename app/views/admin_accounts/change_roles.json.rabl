if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @message != nil
    node(:message) { @message }
end

if @admin_roles != nil
    node(:admin_roles) { @admin_roles }
end