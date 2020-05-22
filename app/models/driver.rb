class Driver < ApplicationRecord

  belongs_to :customer_user, touch: true
  before_create :get_driver_country
  serialize :current_location, Hash
  has_many :orders


  private

  def get_driver_country

    location = self.current_location


    latitude = location[:latitude]

    longitude = location[:longitude]

    results = Geocoder.search([latitude, longitude])

    country_code = results.first.country_code

    self.country = country_code

  end


end
