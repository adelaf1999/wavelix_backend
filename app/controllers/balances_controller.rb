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

        date = payment.created_at.to_datetime.in_time_zone(payment.timezone).strftime('%Y-%m-%d')

        @payments.push({
                           amount: payment.amount.to_f.round(2),
                           fee: payment.fee.to_f.round(2),
                           net: payment.net.to_f.round(2),
                           date: date
                       })

      end

    end

  end

  def driver_balances

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      driver = Driver.find_by(customer_user_id: customer_user.id)

      if driver != nil

        @balance = driver.balance.to_f.round(2)

        @currency = driver.currency

        @payments = []

        driver.payments.order(created_at: :desc).each do |payment|

          date = payment.created_at.to_datetime.in_time_zone(payment.timezone).strftime('%Y-%m-%d')

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

end
