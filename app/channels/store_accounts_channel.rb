class StoreAccountsChannel < ApplicationCable::Channel

  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    admin = Admin.find_by_uid(uid)

    if admin != nil && admin.valid_token?(access_token, client)

      stream_from 'store_accounts_channel'

    else

      reject

    end

  end


  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end



end