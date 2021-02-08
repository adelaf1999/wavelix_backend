class ViewDriverUnsuccessfulOrdersChannel < ApplicationCable::Channel


  def send_current_resolvers(admins_resolving, driver)

    admins = Admin.where(id: admins_resolving)

    current_resolvers = []

    admins.each do |admin|

      current_resolvers.push(admin.full_name)

    end

    ActionCable.server.broadcast "view_driver_unsuccessful_orders_channel_#{driver.id}", {
        current_resolvers: current_resolvers
    }


  end

  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    driver_id = params[:driver_id]

    admin = Admin.find_by_uid(uid)

    driver = Driver.find_by(id: driver_id)

    if admin != nil && admin.valid_token?(access_token, client) && driver != nil

      # Only subscribe to channel if driver has unsuccessful orders

      if admin.has_roles?(:root_admin, :order_manager) && driver.has_unsuccessful_orders?

        stream_from "view_driver_unsuccessful_orders_channel_#{driver.id}"

        admins_resolving = driver.get_admins_resolving

        admins_resolving.push(admin.id)

        driver.update!(admins_resolving: admins_resolving)

        send_current_resolvers(admins_resolving, driver)


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

    driver_id = params[:driver_id]

    admin = Admin.find_by_uid(uid)

    driver = Driver.find_by(id: driver_id)

    if admin != nil && admin.valid_token?(access_token, client) && driver != nil

      admins_resolving = driver.get_admins_resolving

      if admins_resolving.length > 0

        index = admins_resolving.index(admin.id)

        if index != nil

          admins_resolving.delete_at(index)

          driver.update!(admins_resolving: admins_resolving)

          send_current_resolvers(admins_resolving, driver)

        end

      end

    end


  end



end