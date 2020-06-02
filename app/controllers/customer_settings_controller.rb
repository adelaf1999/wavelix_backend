class CustomerSettingsController < ApplicationController

  before_action :authenticate_user!

  include MoneyHelper


  def change_default_currency

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      currency = params[:currency]

      if currency != nil && is_currency_valid?(currency)

        customer_user.update!(default_currency: currency)

        @default_currency = currency

        @success = true

      else

        @success = false

      end

    end


  end

  def index

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      @default_currency = customer_user.default_currency

      @currencies = get_currencies

    end

  end


end
