if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @list != nil
    node(:list) { @list }
end

if @customer != nil
    node(:customer) { @customer }
end