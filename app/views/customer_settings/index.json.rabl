if @default_currency != nil
    node(:default_currency) { @default_currency }
end

if @card_info != nil
    node(:card_info) { @card_info }
end

if @building_name != nil
    node(:building_name) { @building_name }
end

if  @apartment_floor != nil
    node(:apartment_floor) {  @apartment_floor }
end

if @home_address != nil
    node(:home_address) { @home_address }
end


if @phone_number != nil
    node(:phone_number) { @phone_number }
end

if @currencies != nil
    node(:currencies) { @currencies }
end
