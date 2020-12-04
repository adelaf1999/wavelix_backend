if @available_roles != nil
    node(:available_roles) { @available_roles }
end

if @admins != nil
    node(:admins) { @admins }
end