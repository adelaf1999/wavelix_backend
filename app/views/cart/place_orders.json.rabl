if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @invalid_items != nil
    node(:invalid_items) { @invalid_items  }
end