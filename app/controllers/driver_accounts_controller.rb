class DriverAccountsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  include CountriesHelper

  before_action :authenticate_admin!


  def show

    if is_admin_session_expired?(current_admin)

      head 440

    else

      driver = Driver.find_by(id: params[:driver_id])

      if driver != nil

        @success = true

        @profile_picture = driver.profile_picture.url

        @name = driver.name

        @phone_number = driver.get_phone_number

        @country = driver.get_country_name

        @driver_verified = driver.driver_verified

        @account_blocked = driver.account_blocked

        @review_status = driver.review_status

        @registered_at = driver.registered_at_utc

        @latitude = driver.latitude

        @longitude = driver.longitude



        @driver_license_pictures = []

        @national_id_pictures = []

        @vehicle_registration_pictures = []


        driver.driver_license_pictures.each do |picture|

          @driver_license_pictures.push(picture.url)

        end


        driver.national_id_pictures.each do |picture|

          @national_id_pictures.push(picture.url)

        end


        driver.vehicle_registration_document_pictures.each do |picture|

          @vehicle_registration_pictures.push(picture.url)

        end

        @verified_by = driver.verified_by

        @admins_declined = driver.get_admins_declined

        @unverified_reasons = driver.get_unverified_reasons





      else

        @success = false

      end

    end

  end

  def search_driver_accounts

    if is_admin_session_expired?(current_admin)

      head 440

    else

      # search for driver accounts by driver name

      # can also filter accounts by driver_verified, country, account_blocked, and review status

      @driver_accounts = []

      search = params[:search]

      limit = params[:limit]

      driver_verified = params[:driver_verified]

      country = params[:country]

      account_blocked = params[:account_blocked]

      review_status = params[:review_status]


      if search != nil && is_positive_integer?(limit)


        search = search.strip

        drivers = Driver.all.where("name ILIKE ?", "%#{search}%").limit(limit)


        if !driver_verified.blank?

          driver_verified = eval(driver_verified)

          if is_boolean?(driver_verified)

            drivers = drivers.where(driver_verified: driver_verified)

          end

        end


        if !country.blank?

          drivers = drivers.where(country: country)

        end


        if !account_blocked.blank?

          account_blocked = eval(account_blocked)

          if is_boolean?(account_blocked)

            drivers = drivers.where(account_blocked: account_blocked)

          end

        end


        if is_review_status_valid?(review_status)

          review_status = review_status.to_i

          drivers = drivers.where(review_status: review_status)

        end


        drivers = drivers.order(created_at: :desc)

        drivers.each do |driver|

          @driver_accounts.push(get_driver_accounts_item(driver))

        end

      end


    end

  end

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    else

      @driver_accounts = []

      limit = params[:limit]

      if is_positive_integer?(limit)

        drivers = Driver.all.order(created_at: :desc).limit(limit)

        drivers.each do |driver|

          @driver_accounts.push(get_driver_accounts_item(driver))

        end

      end

      @review_status_options = { 0 => 'Unreviewed', 1 => 'Reviewed' }

      @countries = get_countries



    end

  end


  private


  def is_review_status_valid?(review_status)

    if !review_status.blank?

      review_status = review_status.to_i

      Driver.review_statuses.values.include?(review_status)

    else

      false

    end

  end



  def is_boolean?(arg)

    [true, false].include?(arg)

  end

  def get_driver_accounts_item(driver)

    {
        id: driver.id,
        profile_picture: driver.profile_picture.url,
        name: driver.name,
        country: driver.get_country_name,
        driver_verified: driver.driver_verified,
        account_blocked: driver.account_blocked,
        review_status: driver.review_status,
        registered_at: driver.registered_at_utc
    }

  end




end
