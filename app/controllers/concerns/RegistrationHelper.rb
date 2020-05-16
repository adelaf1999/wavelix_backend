module RegistrationHelper

  def is_country_blocked?(country_code)

    blocked_countries = ['IL']

    blocked_countries.include?(country_code)

  end

end