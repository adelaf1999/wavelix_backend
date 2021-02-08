class UnsuccessfulOrdersChannel < ApplicationCable::Channel

  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    admin = Admin.find_by_uid(uid)

    if admin != nil && admin.valid_token?(access_token, client)

      if admin.has_roles?(:root_admin, :order_manager)

        stream_from 'unsuccessful_orders_channel'

      else

        reject

      end

    else

      reject

    end


  end


  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end


end