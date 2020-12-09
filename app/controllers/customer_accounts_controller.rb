class CustomerAccountsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_admin!

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    else

      @customer_accounts = []

      limit = params[:limit]

      if is_positive_integer?(limit)

        customer_users = CustomerUser.all.order(full_name: :asc).limit(limit)

        customer_users.each do |customer_user|

          id = customer_user.id

          full_name = customer_user.full_name

          email = customer_user.get_email

          username = customer_user.get_username

          phone_number = customer_user.phone_number.blank? ? 'N/A' : customer_user.phone_number

          country = customer_user.get_country_name



          @customer_accounts.push({
                                      id: id,
                                      full_name: full_name,
                                      email: email,
                                      username: username,
                                      phone_number: phone_number,
                                      country: country
                                  })

        end


      end


    end

  end

end
