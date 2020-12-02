class AdminHomeController < ApplicationController

  include AdminHelper

  before_action :authenticate_admin!

  # This controller includes actions that can be accessed by any admin with any role(s)



  def change_email

    if is_admin_session_expired?(current_admin)

      head 440

    else


      email = params[:email]

      if email.empty?

        @success = false

        @message = 'Email cannot be empty'

      else

        is_email_valid = EmailValidator.valid?(email)

        if is_email_valid

          admin = Admin.find_by(email: email)

          if admin.nil?

            current_admin.update!(email: email)

            @success = true

            @email = current_admin.email

            @uid = current_admin.uid

          else

            @success = false

            @message = 'Email already exists'

          end


        else

          @success = false

          @message = 'Email is invalid'

        end



      end


    end



  end



  def index

    if is_admin_session_expired?(current_admin)

      head 440

    else


      @profile_photo = current_admin.profile_photo.url

      @name = current_admin.full_name

      @email = current_admin.email


    end


  end


  def get_roles

    if is_admin_session_expired?(current_admin)

      head 440

    else


      @roles = current_admin.roles

    end



  end


end
