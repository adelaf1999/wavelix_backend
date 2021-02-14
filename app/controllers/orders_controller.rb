class OrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper

  include ValidationsHelper

  before_action :authenticate_admin!


  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized

    else

      @orders = []

      limit = params[:limit]


      if is_positive_integer?(limit)

        orders = Order.all.order(created_at: :desc).limit(limit)

        orders.each do |order|

          order_data = {
              id: order.id,
              store_name: order.get_store_name,
              customer_name: order.get_customer_name,
              status: order.status,
              country: order.get_country_name,
              store_handles_delivery: order.store_handles_delivery,
              ordered_at: order.created_at
          }

          driver = Driver.find_by(id: order.driver_id)

          order_data[:driver_name] = driver.nil? ? 'N/A' : driver.name

          @orders.push(order_data)

        end

      end


      @status_options = Order.statuses

      @countries = get_countries


    end

  end

end
