class ViewUnconfirmedOrderChannel < ApplicationCable::Channel

  include UnconfirmedOrdersHelper


  def send_current_reviewers(admins_reviewing, order)

    admins = Admin.where(id: admins_reviewing)

    current_reviewers = []

    admins.each do |admin|

      current_reviewers.push(admin.full_name)

    end

    ActionCable.server.broadcast "view_unconfirmed_order_channel_#{order.id}", {
        current_reviewers: current_reviewers
    }


  end


  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    order_id = params[:order_id]

    admin = Admin.find_by_uid(uid)

    order = Order.find_by(id: order_id)

    if admin != nil && admin.valid_token?(access_token, client) && order != nil

      if admin.has_roles?(:root_admin, :order_manager) && is_order_unconfirmed?(order)

        stream_from "view_unconfirmed_order_channel_#{order.id}"

        admins_reviewing = order.get_admins_reviewing

        admins_reviewing.push(admin.id)

        order.update!(admins_reviewing: admins_reviewing)

        send_current_reviewers(admins_reviewing, order)

      else

        reject

      end

    else

      reject

    end


  end

  def unsubscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    order_id = params[:order_id]

    admin = Admin.find_by_uid(uid)

    order = Order.find_by(id: order_id)

    if admin != nil && admin.valid_token?(access_token, client) && order != nil

      admins_reviewing = order.get_admins_reviewing

      if admins_reviewing.length > 0

        index = admins_reviewing.index(admin.id)

        if index != nil

          admins_reviewing.delete_at(index)

          order.update!(admins_reviewing: admins_reviewing)

          send_current_reviewers(admins_reviewing, order)

        end

      end

    end


  end


end