if @is_registered != nil
    node(:is_registered) { @is_registered }
end

if @driver_verified != nil
    node(:driver_verified) { @driver_verified }
end

if @name != nil
    node(:name) { @name }
end

if @profile_picture_url != nil
    node(:profile_picture_url) { @profile_picture_url }
end

if @has_saved_card != nil
    node(:has_saved_card) { @has_saved_card }
end

if @currencies != nil
    node(:currencies) { @currencies }
end

