module RegistrationHelper

  def is_country_blocked?(country_code)

    blocked_countries = ['IL', 'AF', 'AL', 'BA', 'CD', 'CG', 'CI', 'CU', 'IR', 'IQ', 'KP', 'LR', 'LY', 'MM', 'NG', 'PK', 'SO', 'SS', 'SD', 'SY', 'VE', 'YE', 'ZW']

    blocked_countries.include?(country_code)

  end

end