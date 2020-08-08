class BalancesController < ApplicationController

  before_action :authenticate_user!

  include OrderHelper

  def store_balances

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      @balance = store_user.balance.to_f.round(2)

      @currency = store_user.currency

      @payments = []

      store_user.payments.order(created_at: :desc).each do |payment|

        timezone = get_store_timezone_name(store_user)

        date = payment.created_at.to_datetime.in_time_zone(timezone).strftime('%Y-%m-%d')

        @payments.push({
                           amount: payment.amount.to_f.round(2),
                           fee: payment.fee.to_f.round(2),
                           net: payment.net.to_f.round(2),
                           date: date
                       })

      end

    end

  end

end
