if @profile_photo != nil
    node(:profile_photo) { @profile_photo }
end

if @name != nil
    node(:name) { @name }
end

if @email != nil
    node(:email) { @email }
end
