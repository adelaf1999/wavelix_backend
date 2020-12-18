class DriverAccountsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  include CountriesHelper

  before_action :authenticate_admin!

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
