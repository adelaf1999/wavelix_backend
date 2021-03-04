Timezone::Lookup.config(:google) do |c|
  c.api_key = Rails.env.development? ? ENV.fetch('DEVELOPMENT_GOOGLE_API_KEY') : ENV.fetch('PRODUCTION_GOOGLE_API_KEY')
end