class GeocodeController < ApplicationController

  include OrderHelper

  def reverse_geocode

    latitude = params[:latitude]

    longitude = params[:longitude]

    if !latitude.blank? && !longitude.blank?

      if is_decimal_number?(latitude) && is_decimal_number?(longitude)

        latitude = latitude.to_d

        longitude = longitude.to_d

        geo_location = Geocoder.search([latitude, longitude])

        if geo_location.size > 0

          @success = true

          @country_code = geo_location.first.country_code

        else

          @success = false

        end


      else

        @success = false

      end

    else

      @success = false

    end

  end

end
