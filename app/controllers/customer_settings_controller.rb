class CustomerSettingsController < ApplicationController

  before_action :authenticate_user!

  def index

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      @default_currency = customer_user.default_currency

    end

  end


end
