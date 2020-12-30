class ViewPostCaseChannel < ApplicationCable::Channel


  def send_current_reviewers(admins_reviewing, post_case)

    admins = Admin.where(id: admins_reviewing)

    current_reviewers = []

    admins.each do |admin|

      current_reviewers.push(admin.full_name)

    end

    ActionCable.server.broadcast "view_post_case_channel_#{post_case.id}", {
        current_reviewers: current_reviewers
    }


  end

  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    post_case_id = params[:post_case_id]

    admin = Admin.find_by_uid(uid)

    post_case = PostCase.find_by(id: post_case_id)

    if admin != nil && admin.valid_token?(access_token, client) && post_case != nil

      if admin.has_roles?(:root_admin, :profile_manager)

        stream_from "view_post_case_channel_#{post_case.id}"

        if post_case.unreviewed?

          admins_reviewing = post_case.get_admins_reviewing

          admins_reviewing.push(admin.id)

          post_case.update!(admins_reviewing: admins_reviewing)

          send_current_reviewers(admins_reviewing, post_case)

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

    post_case_id = params[:post_case_id]

    admin = Admin.find_by_uid(uid)

    post_case = PostCase.find_by(id: post_case_id)

    if admin != nil && admin.valid_token?(access_token, client) && post_case != nil

      admins_reviewing = post_case.get_admins_reviewing

      if admins_reviewing.length > 0

        index = admins_reviewing.index(admin.id)

        if index != nil

          admins_reviewing.delete_at(index)

          post_case.update!(admins_reviewing: admins_reviewing)

          send_current_reviewers(admins_reviewing, post_case)

        end

      end

    end


  end

end