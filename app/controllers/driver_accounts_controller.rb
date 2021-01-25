class DriverAccountsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  include CountriesHelper

  before_action :authenticate_admin!


  def decline_verification

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :account_manager)

      head :unauthorized

    else

      driver = Driver.find_by(id: params[:driver_id])

      declined_reason = params[:declined_reason]

      if driver != nil && !declined_reason.blank?

        if driver.driver_verified

          @success = false

        else

          admins_declined = driver.get_admins_declined

          if admins_declined.include?(current_admin.id)

            @success = false

          else

            @success = true

            admins_declined.push(current_admin.id)

            driver.reviewed!

            driver.update!(admins_declined: admins_declined, admins_reviewing: [])

            UnverifiedReason.create!(
                admin_name: current_admin.full_name,
                reason: declined_reason,
                driver_id: driver.id
            )


            driver_account_item = get_driver_accounts_item(driver)

            ActionCable.server.broadcast 'driver_accounts_channel', {
                driver_account_item: driver_account_item
            }

            ActionCable.server.broadcast "driver_account_channel_#{driver.id}", {
                admins_declined: admins_declined,
                review_status: driver.review_status,
                current_reviewers: [],
                unverified_reasons: driver.get_unverified_reasons
            }



          end

        end


      else

        @success = false

      end


    end

  end

  def accept_verification

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :account_manager)

      head :unauthorized

    else

      driver = Driver.find_by(id: params[:driver_id])

      if driver != nil

        if driver.driver_verified

          @success = false

        else

          @success = true

          driver.reviewed!

          driver.update!(
              driver_verified: true,
              verified_by: current_admin.full_name,
              admins_reviewing: []
          )

          driver_account_item = get_driver_accounts_item(driver)

          ActionCable.server.broadcast 'driver_accounts_channel', {
              driver_account_item: driver_account_item
          }

          ActionCable.server.broadcast "driver_account_channel_#{driver.id}", {
              review_status: driver.review_status,
              driver_verified: driver.driver_verified,
              verified_by: driver.verified_by,
              current_reviewers: []
          }

          ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
              driver_verified: driver.driver_verified
          }

          DriverMailer.delay.account_verified(driver.get_email, driver.name)

          message_body = 'Your Wavelix driver account has been successfully verified and you can start making deliveries.'

          message_title = 'Driver Account Verified'

          driver.send_notification(message_body, message_title)


        end

      else

        @success = false

      end

    end

  end


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

        @account_status = driver.account_status

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

        @email = driver.get_email





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

      # can also filter accounts by driver_verified, country, account_status, and review status

      @driver_accounts = []

      search = params[:search]

      limit = params[:limit]

      driver_verified = params[:driver_verified]

      country = params[:country]

      account_status = params[:account_status]

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


        if is_account_status_valid?(account_status)

          account_status = account_status.to_i

          drivers = drivers.where(account_status: account_status)

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

      @review_status_options = Driver.review_statuses

      @countries = get_countries

      @account_status_options = Driver.account_statuses




    end

  end


  private


  def is_account_status_valid?(account_status)

    if !account_status.blank?

      account_status = account_status.to_i

      Driver.account_statuses.values.include?(account_status)

    else

      false

    end

  end


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
        account_status: driver.account_status,
        review_status: driver.review_status,
        registered_at: driver.registered_at_utc
    }

  end




end
