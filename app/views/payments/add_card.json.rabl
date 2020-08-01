if @result != nil
    node(:result) { @result }
end

if @success != nil
    node(:success) { @success }
end

if  @card_info != nil
    node(:card_info) {  @card_info }
end


if @error_code != nil
    node(:error_code) { @error_code }
end

if @redirect_url != nil
    node(:redirect_url) { @redirect_url }
end

if  @error_message != nil
    node(:error_message) {  @error_message }
end