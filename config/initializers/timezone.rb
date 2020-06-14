Timezone::Lookup.config(:google) do |c|
  c.api_key = ENV.fetch('GOOGLE_API_KEY')
end