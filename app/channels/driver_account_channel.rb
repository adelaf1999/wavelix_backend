class DriverAccountChannel < ApplicationCable::Channel

  def send_current_reviewers(admins_reviewing, driver)

    admins = Admin.where(id: admins_reviewing)

    current_reviewers = []

    admins.each do |admin|

      current_reviewers.push(admin.full_name)

    end

    ActionCable.server.broadcast "driver_account_channel_#{driver.id}", {
        current_reviewers: current_reviewers
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

      if admin.has_roles?(:root_admin, :account_manager)

        stream_from "driver_account_channel_#{driver.id}"

        if driver.unreviewed?

          admins_reviewing = driver.get_admins_reviewing

          admins_reviewing.push(admin.id)

          driver.update!(admins_reviewing: admins_reviewing)

          send_current_reviewers(admins_reviewing, driver)

        end

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

      admins_reviewing = driver.get_admins_reviewing

      if admins_reviewing.length > 0

        index = admins_reviewing.index(admin.id)

        if index != nil

          admins_reviewing.delete_at(index)

          driver.update!(admins_reviewing: admins_reviewing)

          send_current_reviewers(admins_reviewing, driver)

        end

      end

    end



  end



end