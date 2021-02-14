class OrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper

  include ValidationsHelper

  before_action :authenticate_admin!


  def search

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized

    else

      # search for orders by store name and customer name

      # filter orders by status, country, store handles delivery

      @orders = []


      store_name = params[:store_name]

      customer_name = params[:customer_name]

      limit = params[:limit]

      status = params[:status]

      country = params[:country]

      store_handles_delivery = params[:store_handles_delivery]


      if store_name != nil && customer_name != nil && is_positive_integer?(limit)

        store_name = store_name.strip

        customer_name = customer_name.strip

        orders = Order.all.where("store_name ILIKE ?", "%#{store_name}%").where("customer_name ILIKE ?", "%#{customer_name}%").limit(limit)


        if is_status_valid?(status)

          status  = status.to_i

          orders  = orders.where(status: status)

        end


        if !country.blank?

          orders = orders.where(country: country)

        end


        if !store_handles_delivery.blank?

          store_handles_delivery = eval(store_handles_delivery)

          if is_boolean?(store_handles_delivery)

            orders = orders.where(store_handles_delivery: store_handles_delivery)

          end


        end


        orders = orders.order(created_at: :desc)


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


    end

  end


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


  private

  def is_boolean?(arg)

    [false, true].include?(arg)

  end

  def is_status_valid?(status)

    if !status.blank?

      status = status.to_i

      Order.statuses.values.include?(status)


    else

      false

    end

  end


end
