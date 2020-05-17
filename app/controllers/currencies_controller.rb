class CurrenciesController < ApplicationController

  include MoneyHelper

  def currencies

    @currencies = get_currencies

  end


end
