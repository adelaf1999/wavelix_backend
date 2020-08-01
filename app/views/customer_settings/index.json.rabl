if @default_currency != nil
    node(:default_currency) { @default_currency }
end

if @card_info != nil
    node(:card_info) { @card_info }
end

if @currencies != nil
    node(:currencies) { @currencies }
end

