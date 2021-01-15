class UnconfirmedOrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper

  include ValidationsHelper

  before_action :authenticate_admin!

  def search_unconfirmed_orders

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      # search for unconfirmed orders by store name or customer name

      # filter orders by country and time exceed

      @unconfirmed_orders = []

      search = params[:search]

      country = params[:country]

      time_exceeded = params[:time_exceeded]


      if search != nil

        search = search.strip

        unconfirmed_orders = get_unconfirmed_orders

        unconfirmed_orders = unconfirmed_orders.where("store_name ILIKE ?", "%#{search}%").or( unconfirmed_orders.where("customer_name ILIKE ?", "%#{search}%") )

        if !country.blank?

          unconfirmed_orders = unconfirmed_orders.where(country: country)

        end

        if !time_exceeded.blank? && is_positive_integer?(time_exceeded)

          time_exceeded = time_exceeded.to_i

          unconfirmed_orders = unconfirmed_orders.where('delivery_time_limit <= ?', time_exceeded.minutes.ago)

        end


        unconfirmed_orders.each do |order|

          @unconfirmed_orders.push( get_unconfirmed_orders_item(order) )

        end

      end

    end

  end

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      @unconfirmed_orders = []

      unconfirmed_orders = get_unconfirmed_orders

      unconfirmed_orders.each do |order|

        @unconfirmed_orders.push( get_unconfirmed_orders_item(order) )

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

  private



  def get_unconfirmed_orders_item(order)

    {
        id: order.id,
        store_name: order.get_store_name,
        customer_name: order.get_customer_name,
        country: order.get_country_name,
        ordered_at: order.created_at,
        delivery_time_limit: order.delivery_time_limit
    }


  end

  def get_unconfirmed_orders

    Order.all.where(status: 2, store_handles_delivery: true, store_confirmation_status: 2).where('delivery_time_limit <= ?', DateTime.now.utc)

  end


end
