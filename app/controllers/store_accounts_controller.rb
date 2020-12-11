class StoreAccountsController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_admin!


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


    end

  end

  private

  def get_store_accounts_item(store_user)

    {
        id: store_user.id,
        store_username: store_user.get_username,
        store_name: store_user.store_name,
        store_owner: store_user.store_owner_full_name,
        country: store_user.get_country_name,
        account_status: store_user.status,
        review_status: store_user.review_status,
        registed_at: store_user.registered_at_utc
    }

  end

end
