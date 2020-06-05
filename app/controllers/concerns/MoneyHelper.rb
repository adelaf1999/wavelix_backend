module MoneyHelper

  require 'faraday'
  require 'faraday_middleware'
  require 'net/http'

  def get_currencies


    ["AED", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN", "BBD", "BDT", "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", "BWP", "BYN", "BZD", "CAD", "CHF", "CLP", "CNY", "COP", "CRC", "CVE", "CZK", "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD", "FKP", "GBP", "GEL", "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "INR", "ISK", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LSL", "MAD", "MDL", "MGA", "MKD", "MNT", "MOP", "MRU", "MUR", "MVR", "MWK", "MXN", "MYR", "MZN", "NAD", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PLN", "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SEK", "SGD", "SHP", "SLL", "SRD", "STN", "SZL", "THB", "TJS", "TMT", "TND", "TOP", "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "USD", "UYU", "UZS", "VND", "VUV", "WST", "XAF", "XCD", "XOF", "XPF", "XSU", "ZAR", "ZMW"]

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


    response = conn.get('latest', access_key: ENV.fetch('FIXER_IO_API_KEY'), base: base_currency)

    # success: Returns true or false depending on whether or not your API request has succeeded.
    # timestamp:	Returns the exact date and time (UNIX time stamp) the given rates were collected.
    # base:	Returns the three-letter currency code of the base currency used for this request.
    # rates:	Returns exchange rate data for the currencies you have requested.

    response.body['rates']

  end



end