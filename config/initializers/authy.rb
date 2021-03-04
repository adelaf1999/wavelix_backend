Authy.api_key = Rails.env.development? ? ENV.fetch('DEVELOPMENT_AUTHY_API_KEY')  :  ENV.fetch('PRODUCTION_AUTHY_API_KEY')
Authy.api_uri = 'https://api.authy.com/'