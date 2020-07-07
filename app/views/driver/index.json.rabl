if @is_registered != nil
    node(:is_registered) { @is_registered }
end

if @driver_verified != nil
    node(:driver_verified) { @driver_verified }
end

if @name != nil
    node(:name) { @name }
end

if @profile_picture != nil
    node(:profile_picture) { @profile_picture }
end

if @currencies != nil
    node(:currencies) { @currencies }
end