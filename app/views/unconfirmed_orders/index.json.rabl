if @time_exceeded_filters != nil
    node(:time_exceeded_filters) { @time_exceeded_filters }
end

if @unconfirmed_orders != nil
    node(:unconfirmed_orders) { @unconfirmed_orders }
end


if @countries != nil
    node(:countries) { @countries }
end