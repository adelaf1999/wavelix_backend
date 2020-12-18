class DriverAccountsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  include CountriesHelper

  before_action :authenticate_admin!


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

      @verified_options = { yes: true, no: false  }

      @account_blocked_options = { yes: true, no: false }

      @review_status_options = { unreviewed: 0, reviewed: 1 }

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
        verified: driver.driver_verified ? 'yes' : 'no',
        account_blocked: driver.account_blocked ? 'yes' : 'no',
        review_status: driver.review_status,
        registered_at: driver.registered_at_utc
    }

  end




end
