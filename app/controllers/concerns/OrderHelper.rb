module OrderHelper

  require 'faraday'
  require 'faraday_middleware'
  require 'net/http'



  def calculate_exclusive_delivery_fee_usd(delivery_location, store_location)

    # Returns delivery fee from store to delivery location in USD

    latitude = delivery_location[:latitude]

    longitude = delivery_location[:longitude]

    store_latitude = store_location[:latitude]

    store_longitude = store_location[:longitude]

    url = 'https://maps.googleapis.com/maps/api/distancematrix'

    conn = Faraday.new(url: url) do |faraday|
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end

    response = Rails.cache.fetch("#{store_latitude},#{store_longitude}|#{latitude},#{longitude}", expires_in: 30.minutes) do
      conn.get(
          'json',
          units: 'metric',
          origins: "#{store_latitude},#{store_longitude}",
          destinations: "#{latitude},#{longitude}",
          key: ENV.fetch('GOOGLE_API_KEY')
      )
    end

    data = response.body['rows'][0]['elements'][0]

    travel_distance = data['distance']['value'] / 1000 # KM

    travel_time = data['duration']['value'] / 60 # Minutes

    0.0189 * travel_time + 0.533 * travel_distance + 2 # in USD

  end

  def calculate_distance_km(loc1, loc2)

    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[:latitude]-loc1[:latitude]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[:longitude]-loc1[:longitude]) * rad_per_deg


    lat1_rad = loc1[:latitude] * rad_per_deg
    lat2_rad = loc2[:latitude] * rad_per_deg

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    (rm * c) / 1000.0 # Delta in KM

  end

  def is_order_type_valid?(order_type)


    res = /^(?<num>\d+)$/.match(order_type)

    if res == nil

      false

    else

      order_type = order_type.to_i

      order_type == 0 || order_type == 1

    end


  end

end