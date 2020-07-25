if @result != nil
    node(:result) { @result }
end

if @success != nil
    node(:success) { @success }
end

if @error_code != nil
    node(:error_code) { @error_code }
end

if @next_action != nil
    node(:next_action) { @next_action }
end

if  @error_message != nil
    node(:error_message) {  @error_message }
end