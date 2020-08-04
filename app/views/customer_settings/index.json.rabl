if @default_currency != nil
    node(:default_currency) { @default_currency }
end

if @card_info != nil
    node(:card_info) { @card_info }
end

if @currencies != nil
    node(:currencies) { @currencies }
end

if @building_name != nil
    node(:building_name) { @building_name }
end

if  @apartment_floor != nil
    node(:apartment_floor) {  @apartment_floor }
end