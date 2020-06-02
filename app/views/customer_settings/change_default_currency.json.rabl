if @default_currency != nil
    node(:default_currency) { @default_currency }
end

if @success != nil
    node(:success) { @success  }
end

