class UnconfirmedOrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper

  before_action :authenticate_admin!

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      @unconfirmed_orders = []

      unconfirmed_orders = Order.all.where(status: 2, store_handles_delivery: true, store_confirmation_status: 2).where('delivery_time_limit <= ?', DateTime.now.utc)

      unconfirmed_orders.each do |order|

        @unconfirmed_orders.push({
                                    id: order.id,
                                    store_name: order.get_store_name,
                                    customer_name: order.get_customer_name,
                                    country: order.get_country_name,
                                    ordered_at: order.created_at,
                                    delivery_time_limit: order.delivery_time_limit
                                 })

      end


      @countries = get_countries

      @time_exceeded_filters = {
          30 => 'More than 30 minutes',
          60 => 'More than 1 hour',
          180 => 'More than 3 hours',
          360 => 'More than 6 hours',
          540 => 'More than 9 hours',
          720 => 'More than 12 hours',
          900 => 'More than 15 hours',
          1440 => 'More than 1 day',
          4320 => 'More than 3 days',
          10080 => 'More than 7 days',
          14400 => 'More than 10 days',
          20160 => 'More than 14 days',
          28800 => 'More than 20 days',
          43200 => 'More than 30 days',
          64800 => 'More than 45 days',
          86400 => 'More than 60 days'
      }


    end

  end


end
