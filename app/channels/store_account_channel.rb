class StoreAccountChannel < ApplicationCable::Channel


  def send_current_reviewers(admins_reviewing, store_user)

    admins = Admin.where(id: admins_reviewing)

    current_reviewers = []

    admins.each do |admin|

      current_reviewers.push(admin.full_name)

    end

    ActionCable.server.broadcast "store_account_channel_#{store_user.id}", {
        current_reviewers: current_reviewers
    }


  end

  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    store_user_id = params[:store_user_id]

    admin = Admin.find_by_uid(uid)

    store_user = StoreUser.find_by(id: store_user_id)

    if admin != nil && admin.valid_token?(access_token, client) && store_user != nil

      if admin.has_roles?(:root_admin, :account_manager)

        stream_from "store_account_channel_#{store_user.id}"

        if store_user.unreviewed?

          admins_reviewing = store_user.get_admins_reviewing

          admins_reviewing.push(admin.id)

          store_user.update!(admins_reviewing: admins_reviewing)

          send_current_reviewers(admins_reviewing, store_user)

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

    store_user_id = params[:store_user_id]

    admin = Admin.find_by_uid(uid)

    store_user = StoreUser.find_by(id: store_user_id)

    if admin != nil && admin.valid_token?(access_token, client) && store_user != nil

      admins_reviewing = store_user.get_admins_reviewing

      if admins_reviewing.length > 0

        index = admins_reviewing.index(admin.id)

        if index != nil

          admins_reviewing.delete_at(index)

          store_user.update!(admins_reviewing: admins_reviewing)

          send_current_reviewers(admins_reviewing, store_user)


        end


      end

    else

      reject

    end


  end


end