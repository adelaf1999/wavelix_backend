if @status_options != nil
    node(:status_options) { @status_options }
end

if @orders != nil
    node(:orders) { @orders }
end


if @countries != nil
    node(:countries) { @countries }
end