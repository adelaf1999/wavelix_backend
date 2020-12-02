class AdminHomeController < ApplicationController

  include AdminHelper

  before_action :authenticate_admin!

  # This controller includes actions that can be accessed by any admin with any role(s)


  def change_password

    if is_admin_session_expired?(current_admin)

      head 440

    else

      password = params[:password]

      if !password.blank?

        if password.length < 8

          @success = false

          @message = 'Password must be at least 8 characters long'

        else

          current_admin.update!(password: password)

          @success = true

        end

      else

        @success = false

        @message = 'Password cannot be empty'

      end

    end

  end


  def change_email

    if is_admin_session_expired?(current_admin)

      head 440

    else

      email = params[:email]

      if email.blank?

        @success = false

        @message = 'Email cannot be empty'

      else

        is_email_valid = EmailValidator.valid?(email)

        if is_email_valid

          if can_use_email?(email)

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

  private

  def can_use_email?(email)

    # If the admin is nil that means the email is not being used by any other account and it can be used

    admin = Admin.find_by(email: email)

    admin.nil?

  end


end
