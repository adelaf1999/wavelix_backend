class CustomerRegistrationController < ApplicationController

  include CountriesHelper

  def index

    @whitelisted_countries = get_whitelisted_countries

  end

end
