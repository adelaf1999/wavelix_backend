if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @invalid_stores != nil
    node(:invalid_stores) { @invalid_stores  }
end