class UnsuccessfulOrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper


  before_action :authenticate_admin!

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized


    else

      @drivers_unsuccessful_orders = []

      driver_ids = Order.all.where(status: 2, store_confirmation_status: 2, store_handles_delivery: false, store_fulfilled_order: true, driver_fulfilled_order: false).where('delivery_time_limit <= ?', DateTime.now.utc).distinct.pluck(:driver_id)

      drivers_unsuccessful_orders = Driver.where(id: driver_ids)

      drivers_unsuccessful_orders.each do |driver|

        @drivers_unsuccessful_orders.push({
                                              id: driver.id,
                                              name: driver.name,
                                              country: driver.get_country_name
                                          })

      end


      @countries = get_countries



    end

  end




end
