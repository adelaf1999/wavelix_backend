if @success != nil
    node(:success) { @success }
end

if @total != nil
    node(:total) { @total }
end

if @currency != nil
    node(:currency) { @currency }
end

if @fees != nil
    node(:fees) { @fees }
end