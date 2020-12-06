if @success != nil
    node(:success) { @success }
end

if @admin_profile_photo != nil
    node(:admin_profile_photo) { @admin_profile_photo }
end

if @admin_full_name != nil
    node(:admin_full_name) { @admin_full_name }
end

if @admin_email != nil
    node(:admin_email) { @admin_email }
end

if @admin_roles != nil
    node(:admin_roles) { @admin_roles }
end

if @available_roles != nil
    node(:available_roles) { @available_roles }
end

if @current_sign_in_ip != nil
    node(:current_sign_in_ip) { @current_sign_in_ip }
end

if @last_sign_in_ip != nil
    node(:last_sign_in_ip) { @last_sign_in_ip }
end