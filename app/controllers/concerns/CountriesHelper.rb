module CountriesHelper



  def is_country_blocked?(country_code)

    whitelisted_countries = get_whitelisted_countries

    !whitelisted_countries.include?(country_code)


  end

  def get_countries

    {
        'LB' =>  'Lebanon',
        'NL' => 'Netherlands'
    }

  end


  def get_phone_extensions

    phone_extensions = []

    countries = get_countries

    countries.each do |code, name|

      extension = "+#{ISO3166::Country.find_country_by_alpha2(code).country_code}"

      phone_extensions.push({name: name, extension: extension, code: code })

    end


    phone_extensions


  end


  def get_whitelisted_countries

    countries = get_countries

    countries.keys

  end




end