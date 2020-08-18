if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @invalid_stores != nil
    node(:invalid_stores) { @invalid_stores  }
end

if @error_message != nil
    node(:error_message) { @error_message }
end

if  @redirect_url != nil
    node(:redirect_url) {  @redirect_url }
end