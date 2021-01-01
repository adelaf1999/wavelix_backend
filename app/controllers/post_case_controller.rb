class PostCaseController < ApplicationController

  before_action :authenticate_user!

  include ValidationsHelper

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

              post_case = PostCase.create!(post_id: post.id)

              create_post_report(post, post_case, additional_info, report_type)

              # Send the post case to the post cases page


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


                # Send the post case item to the post cases page


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
