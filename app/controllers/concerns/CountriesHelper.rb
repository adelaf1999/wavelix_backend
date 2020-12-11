module CountriesHelper



  def is_country_blocked?(country_code)

    blocked_countries = get_blocked_countries

    blocked_countries.include?(country_code)

  end

  def get_countries

    countries = ISO3166::Country.translations

    blocked_countries = get_blocked_countries

    blocked_countries.each do |blocked_country|

      countries.delete(blocked_country)

    end

    countries

  end


  private

  def get_blocked_countries

    ['IL', 'AF', 'AL', 'BA', 'CD', 'CG', 'CI', 'CU', 'IR', 'IQ', 'KP', 'LR', 'LY', 'MM', 'NG', 'PK', 'SO', 'SS', 'SD', 'SY', 'VE', 'YE', 'ZW']

  end

end