module MoneyHelper

  require 'faraday'
  require 'faraday_middleware'
  require 'net/http'

  def get_currencies

    ['EUR', 'USD']

  end

  def is_currency_valid?(code)

    currencies = get_currencies

    currencies.include?(code)

  end


  def get_exchange_rates(base_currency)

    url = 'https://data.fixer.io/api'

    conn = Faraday.new(url: url) do |faraday|
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end


    response = Rails.cache.fetch("exchange_rates_#{base_currency}", expires_in: 12.hours) do
      conn.get('latest', access_key: ENV.fetch('FIXER_IO_API_KEY'), base: base_currency)
    end


    # success: Returns true or false depending on whether or not your API request has succeeded.
    # timestamp:	Returns the exact date and time (UNIX time stamp) the given rates were collected.
    # base:	Returns the three-letter currency code of the base currency used for this request.
    # rates:	Returns exchange rate data for the currencies you have requested.

    response.body['rates']

  end



end