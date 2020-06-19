if @success != nil
    node(:success) { @success }
end

if @seconds_left != nil
    node(:seconds_left) { @seconds_left }
end