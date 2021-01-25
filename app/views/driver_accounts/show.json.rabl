if @success != nil
    node(:success) { @success }
end

if @profile_picture != nil
    node(:profile_picture) { @profile_picture }
end

if @name != nil
    node(:name) { @name }
end

if @phone_number != nil
    node(:phone_number) { @phone_number }
end

if @country != nil
    node(:country) { @country }
end

if @driver_verified != nil
    node(:driver_verified) { @driver_verified }
end

if @account_status != nil
    node(:account_status) { @account_status }
end

if @review_status != nil
    node(:review_status) { @review_status }
end

if @registered_at != nil
    node(:registered_at) { @registered_at }
end

if @latitude != nil
    node(:latitude) { @latitude }
end

if @longitude != nil
    node(:longitude) { @longitude }
end

if @driver_license_pictures != nil
    node(:driver_license_pictures) { @driver_license_pictures }
end

if @national_id_pictures != nil
    node(:national_id_pictures) { @national_id_pictures }
end

if @vehicle_registration_pictures != nil
    node(:vehicle_registration_pictures) { @vehicle_registration_pictures }
end

if @verified_by != nil
    node(:verified_by) { @verified_by }
end

if @admins_declined != nil
    node(:admins_declined) { @admins_declined }
end

if @unverified_reasons != nil
    node(:unverified_reasons) { @unverified_reasons }
end

if @email != nil
    node(:email) { @email }
end