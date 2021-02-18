if @currencies != nil
    node(:currencies) { @currencies }
end

if  @phone_extensions != nil
    node(:phone_extensions) {  @phone_extensions }
end

if @whitelisted_countries != nil
    node(:whitelisted_countries) { @whitelisted_countries }
end