class StoreAccountsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  include CountriesHelper

  before_action :authenticate_admin!


  def show

    if is_admin_session_expired?(current_admin)

      head 440

    else

      store_user = StoreUser.find_by(id: params[:store_user_id])

      if store_user != nil

        @success = true

        @store_owner = store_user.store_owner_full_name

        @store_username =  store_user.get_username

        @store_name = store_user.store_name

        @status = store_user.status

        @review_status = store_user.review_status

        @country =  store_user.get_country_name

        @has_sensitive_products = store_user.has_sensitive_products

        @business_license =  store_user.store_business_license.url

        @registered_at =  store_user.registered_at_utc

        @location =  store_user.store_address

        @store_owner_number = store_user.store_owner_work_number

        @store_number =  store_user.store_number

        @verified_by = store_user.verified_by

        @store_email = store_user.get_email

        admins_declined = store_user.get_admins_declined

        if admins_declined.include?(current_admin.id)

          @declined_verification = true

        else

          @declined_verification = false

        end






      else

        @success = false

      end


    end

  end


  def search_store_accounts

    if is_admin_session_expired?(current_admin)

      head 440

    else

      # search for store accounts by store username, store owner name or store name

      # can also filter store by country, status, and review status


      @store_accounts = []

      search = params[:search]

      limit = params[:limit]

      country = params[:country]

      status = params[:status]

      review_status = params[:review_status]


      if search != nil && is_positive_integer?(limit)

        search = search.strip

        store_user_ids = []


        users_by_username = User.all.where(user_type: 1).where("username ILIKE ?", "%#{search}%").limit(limit)

        users_by_username.each do |user|

          store_user = StoreUser.find_by(store_id: user.id)

          store_user_ids.push(store_user.id)

        end


        store_users_by_owner_name = StoreUser.all.where("store_owner_full_name ILIKE ?", "%#{search}%").where.not(id: store_user_ids).limit(limit)

        store_users_by_owner_name.each do |store_user|

          store_user_ids.push(store_user.id)

        end


        store_users_by_store_name = StoreUser.all.where("store_name ILIKE ?", "%#{search}%").where.not(id: store_user_ids).limit(limit)

        store_users_by_store_name.each do |store_user|

          store_user_ids.push(store_user.id)

        end


        store_user_ids.uniq!


        store_users = StoreUser.where(id: store_user_ids)


        if !country.blank?

          store_users = store_users.where(store_country: country)

        end

        if is_status_valid?(status)

          status = status.to_i

          store_users = store_users.where(status: status)

        end


        if is_review_status_valid?(review_status)

          review_status = review_status.to_i

          store_users = store_users.where(review_status: review_status)

        end



        store_users = store_users.order(created_at: :desc)


        store_users.each do |store_user|

          @store_accounts.push(get_store_accounts_item(store_user))

        end



      end


    end

  end

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    else

      @store_accounts = []

      limit = params[:limit]

      if is_positive_integer?(limit)

        store_users = StoreUser.all.order(created_at: :desc).limit(limit)

        store_users.each do |store_user|

          @store_accounts.push(get_store_accounts_item(store_user))

        end

      end


      @account_status_options = {0 => 'Unverified', 1 => 'Verified'}

      @review_status_options = { 0 => 'Unreviewed', 1 => 'Reviewed' }

      @countries = get_countries


    end

  end

  private



  def is_review_status_valid?(review_status)

    if !review_status.blank?

      review_status = review_status.to_i

      StoreUser.review_statuses.values.include?(review_status)

    else

      false

    end

  end

  def is_status_valid?(status)

    if !status.blank?

      status = status.to_i

      StoreUser.statuses.values.include?(status)

    else

      false

    end

  end

  def get_store_accounts_item(store_user)

    {
        id: store_user.id,
        store_username: store_user.get_username,
        store_name: store_user.store_name,
        store_owner: store_user.store_owner_full_name,
        country: store_user.get_country_name,
        account_status: store_user.status,
        review_status: store_user.review_status,
        registered_at: store_user.registered_at_utc
    }

  end

end
