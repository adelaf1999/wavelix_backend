if @success != nil
    node(:success) { @success }
end

if @profile_data != nil
    node(:profile_data) { @profile_data }
end

if @current_store_unverified != nil
    node(:current_store_unverified) {  @current_store_unverified  }
end

if @customer_country != nil
    node(:customer_country) { @customer_country }
end

if @profile_blocked != nil
    node(:profile_blocked) { @profile_blocked }
end

if @report_types != nil
    node(:report_types) { @report_types }
end