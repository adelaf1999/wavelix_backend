if @roles != nil
    node(:roles) { @roles }
end

if @status != nil
    node(:status) { @status }
end