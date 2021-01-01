class PostCaseController < ApplicationController

  include AdminHelper

  include ValidationsHelper

  before_action :authenticate_user!, only: [:create]

  before_action :authenticate_admin!, only: [:index, :search_post_cases]


  def search_post_cases

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :profile_manager)

      head :unauthorized

    else

      # search for post cases by post author username

      # can also filter by review_status

      @post_cases = []

      search = params[:search]

      limit = params[:limit]

      review_status = params[:review_status]

      if search != nil && is_positive_integer?(limit)

        search = search.strip

        post_cases = PostCase.all.where("post_author_username ILIKE ?", "%#{search}%").limit(limit)

        if is_review_status_valid?(review_status)

          review_status = review_status.to_i

          post_cases = post_cases.where(review_status: review_status)

        end

        post_cases = post_cases.order(created_at: :desc)

        post_cases.each do |post_case|

          @post_cases.push(get_post_case_item(post_case))

        end


      end

    end

  end

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :profile_manager)

      head :unauthorized

    else

      @post_cases = []

      limit = params[:limit]

      if is_positive_integer?(limit)

        post_cases = PostCase.all.order(created_at: :desc).limit(limit)

        post_cases.each do |post_case|

          @post_cases.push(get_post_case_item(post_case))

        end

      end

      @review_status_options = { 0 => 'Unreviewed', 1 => 'Reviewed' }


    end

  end


  def create

    post = Post.find_by(id: params[:post_id])

    if post != nil

      report_type = params[:report_type]

      if is_whole_number?(report_type)

        report_type = report_type.to_i

        if is_report_type_valid?(report_type)

          # A user cant report his own posts

          # A user can report a post once and only once

          if  ( post.author_id != current_user.id )  &&  ( PostReport.find_by(user_id: current_user.id, post_id: post.id) == nil )

            @success = true

            @message = 'A report has been successfully created.'

            additional_info = params[:additional_info]

            if post.post_case == nil

              post_case = PostCase.create!(post_id: post.id, post_author_id: post.author_id, post_author_username: post.author_username)

              create_post_report(post, post_case, additional_info, report_type)

              ActionCable.server.broadcast 'post_cases_channel', {
                  new_post_case: true
              }

              message = 'A new case has been opened for a post. Click the button below to view it now.'

              admins = Admin.role_root_admins + Admin.role_profile_managers

              admins = admins.uniq

              admins.each do |admin|

                AdminAccountMailer.delay.post_case_opened_notice(admin.email, message, post_case.id)

              end


            else

              post_case = post.post_case

              if report_type == 0

                post_case.unreviewed!

                create_post_report(post, post_case, additional_info, report_type)

                post_case.update!(admins_reviewed: [])


                ActionCable.server.broadcast "view_post_case_channel_#{post_case.id}", {
                    review_status: post_case.review_status,
                    post_complaints: post_case.get_post_complaints,
                    admins_reviewed: post_case.get_admins_reviewed,
                    reviewed_by: []
                }
                

                ActionCable.server.broadcast 'post_cases_channel', {
                    new_post_case: true
                }


                message = 'A new case has been opened for a post claiming copyright violation. Click the button below to view it now.'

                admins = Admin.role_root_admins + Admin.role_profile_managers

                admins = admins.uniq

                admins.each do |admin|

                  AdminAccountMailer.delay.post_case_opened_notice(admin.email, message, post_case.id)

                end


              else

                create_post_report(post, post_case, additional_info, report_type)

                ActionCable.server.broadcast "view_post_case_channel_#{post_case.id}", {
                    post_complaints: post_case.get_post_complaints
                }


              end


            end

          else

            @success = false

            @message = 'A report has already been made for this post.'

          end


        else

          @success = false

        end


      else

        @success = false

      end



    else

      @success = false

      @message = 'The post being reported has been deleted.'

    end

  end

  private


  def is_review_status_valid?(review_status)

    if !review_status.blank?

      review_status = review_status.to_i

      PostCase.review_statuses.values.include?(review_status)

    else

      false

    end

  end

  def get_post_case_item(post_case)

    {
        id: post_case.id,
        author_username: post_case.post_author_username,
        review_status: post_case.review_status
    }

  end


  def create_post_report(post, post_case, additional_info, report_type)

    PostReport.create!(
        user_id: current_user.id,
        post_id: post.id,
        post_case_id: post_case.id,
        additional_information: additional_info.blank? ? '' : additional_info,
        report_type: report_type
    )

  end

  def is_report_type_valid?(report_type)

    PostReport.report_types.values.include?(report_type)

  end

end
