class UnsuccessfulOrdersController < ApplicationController

  include AdminHelper

  include CountriesHelper


  before_action :authenticate_admin!


  def search_drivers

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized


    else

      # search for drivers with unsuccessful orders by name

      # filter orders by country

      @drivers = []

      search = params[:search]

      country = params[:country]

      if search != nil

        search = search.strip

        drivers = get_drivers

        drivers = drivers.where("name ILIKE ?", "%#{search}%")


        if !country.blank?

          drivers = drivers.where(country: country)

        end


        drivers.each do |driver|

          @drivers.push(get_driver_item(driver))

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

      @drivers = []

      drivers = get_drivers

      drivers.each do |driver|

        @drivers.push(get_driver_item(driver))

      end


      @countries = get_countries



    end

  end


  private


  def get_driver_item(driver)

    {
        id: driver.id,
        name: driver.name,
        country: driver.get_country_name
    }


  end

  def get_drivers

    # Get all drivers with unsuccessful orders

    driver_ids = Order.all.where(
        status: 2,
        store_confirmation_status: 2,
        store_handles_delivery: false,
        store_fulfilled_order: true,
        driver_fulfilled_order: false
    ).where('delivery_time_limit <= ?', DateTime.now.utc).distinct.pluck(:driver_id)

    Driver.where(id: driver_ids)


  end




end
