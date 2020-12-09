class CustomerAccountsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_admin!


  def search_customer_accounts

    if is_admin_session_expired?(current_admin)

      head 440

    else

      # search for customer accounts by full name, username, or phone number

      @customer_accounts = []

      search = params[:search]

      limit = params[:limit]

      if search != nil && is_positive_integer?(limit)

        search = search.strip

        customer_user_ids = []


        users_by_username = User.all.where(user_type: 0).where("username ILIKE ?", "%#{search}%").limit(limit)

        users_by_username.each do |user|

          customer_user = CustomerUser.find_by(customer_id: user.id)

          customer_user_ids.push(customer_user.id)

        end


        customer_users_by_full_name = CustomerUser.all.where("full_name ILIKE ?", "%#{search}%").where.not(customer_id: customer_user_ids).limit(limit)

        customer_users_by_full_name.each do |customer_user|

          customer_user_ids.push(customer_user.id)

        end


        customer_users_by_number = CustomerUser.all.where("phone_number ILIKE ?", "%#{search}%").where.not(customer_id: customer_user_ids, phone_number: nil).limit(limit)

        customer_users_by_number.each do |customer_user|

          customer_user_ids.push(customer_user.id)

        end


        customer_user_ids.uniq!


        combined_customer_users_search = CustomerUser.where(id: customer_user_ids)

        combined_customer_users_search.each do |customer_user|

          @customer_accounts.push(get_customer_user_account(customer_user))

        end

        @customer_accounts = @customer_accounts.sort_by { |hsh| hsh[:full_name] } 


      end


    end

  end

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    else

      @customer_accounts = []

      limit = params[:limit]

      if is_positive_integer?(limit)

        customer_users = CustomerUser.all.order(full_name: :asc).limit(limit)

        customer_users.each do |customer_user|

          @customer_accounts.push(get_customer_user_account(customer_user))

        end


      end


    end

  end

  private

  def get_customer_user_account(customer_user)

    id = customer_user.id

    full_name = customer_user.full_name

    email = customer_user.get_email

    username = customer_user.get_username

    phone_number = customer_user.phone_number.blank? ? 'N/A' : customer_user.phone_number

    country = customer_user.get_country_name

    {
        id: id,
        full_name: full_name,
        email: email,
        username: username,
        phone_number: phone_number,
        country: country
    }



  end

end
