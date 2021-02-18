class StoreRegistrationController < ApplicationController

  include MoneyHelper

  include CountriesHelper

  def index

    @currencies = get_currencies

    @phone_extensions = get_phone_extensions

    @whitelisted_countries = get_whitelisted_countries

  end


end
