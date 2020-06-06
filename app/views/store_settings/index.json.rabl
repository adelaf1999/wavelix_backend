if @maximum_delivery_distance != nil
    node(:maximum_delivery_distance) { @maximum_delivery_distance }
end

if @handles_delivery != nil
    node(:handles_delivery) { @handles_delivery }
end

if @status != nil
    node(:status) { @status }
end

if @location != nil
    node(:location) { @location }
end