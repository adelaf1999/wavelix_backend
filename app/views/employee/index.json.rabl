if @roles != nil
    node(:roles) { @roles }
end

if @employees != nil
    node(:employees) { @employees }
end