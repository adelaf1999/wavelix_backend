if @currency != nil
    node(:currency) { @currency }
end

if @balance != nil
    node(:balance) { @balance }
end

if @payments != nil
    node(:payments) { @payments }
end