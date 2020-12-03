class AdminAccountsController < ApplicationController

  include AdminHelper

  before_action :authenticate_admin!


  def create

    # Only a root admin can create admin accounts (including root admin accounts)

    # Error codes

    # { 0: EMAIL_ERROR, 1: PASSWORD_ERROR, 2: FULL_NAME_ERROR, 3: PROFILE_PHOTO_ERROR }

    # { 4: ROLES_ERROR, 5: CREATE_ERROR }

    if is_admin_session_expired?(current_admin)

      head 440


    elsif !current_admin.has_roles?(:root_admin)

      head :unauthorized

    else

      email = params[:email]

      password = params[:password]

      full_name = params[:full_name]

      profile_photo = params[:profile_photo]

      roles = params[:roles]

      admin = Admin.new


      # Validate Email

      if email.blank?

        @success = false

        @error_code = 0

        @message = 'Email cannot be empty'

        return

      else

        is_email_valid = EmailValidator.valid?(email)

        if is_email_valid

          if can_use_email?(email)

            admin.email = email

          else

            @success = false

            @error_code = 0

            @message = 'Email already exists'

            return

          end


        else

          @success = false

          @error_code = 0

          @message = 'Email is invalid'

          return

        end

      end


      # Validate password

      if password.blank?

        @success = false

        @error_code = 1

        @message = 'Password cannot be empty'

        return

      else


        if password.length < 8

          @success = false

          @error_code = 1

          @message = 'Password must be at least 8 characters long'

          return

        else

          admin.password = password

        end


      end


      # Validate full name

      if full_name.blank?

        @success = false

        @error_code = 2

        @message = 'Full name cannot be empty'

        return

      else

        admin.full_name = full_name

      end


      # Validate profile photo

      if profile_photo.blank?

        @success = false

        @error_code = 3

        @message = 'Profile photo cannot be empty'

        return

      else

        if !profile_photo.is_a?(ActionDispatch::Http::UploadedFile) || !is_profile_photo_valid?(profile_photo)

          @success = false

          @error_code = 3

          @message = 'Profile photo is invalid'

          return

        else

          admin.profile_photo = profile_photo

        end

      end


      if roles.blank?

        @success = false

        @error_code = 4

        @message = 'Roles cannot be empty'

        return

      else

        begin
          
          roles = eval(roles)

          if roles.instance_of?(Array)

            if roles.length == 0

              @success = false

              @error_code = 4

              @message = 'Please select at least one role'

              return

            else

              roles = roles.map &:to_sym


              if are_roles_valid?(roles)

                admin.roles = roles

              else

                @success = false

                @error_code = 4

                @message = 'Roles are invalid'

                return

              end


            end


          else

            @success = false

            @error_code = 4

            @message = 'Roles are invalid'

            return


          end


        rescue => e


          @success = false

          @error_code = 4

          @message = 'Roles are invalid'

          return


        end





      end


      if admin.save!

        @success = true

      else

        @success = false

        @error_code = 5

        @message = 'Error creating admin account'

      end



    end

  end

  private


  def are_roles_valid?(roles)

    valid = true

    roles.each do |role|

      if !Admin::ROLES.include?(role)

        valid = false

        break

      end

    end

    valid

  end

  def is_profile_photo_valid?(profile_photo)

    filename = profile_photo.original_filename.split('.')

    extension = filename[filename.length - 1]

    valid_extensions = %w(png jpeg jpg gif)

    valid_extensions.include?(extension)

  end

  def can_use_email?(email)

    # If the admin is nil that means the email is not being used by any other account and it can be used

    admin = Admin.find_by(email: email)

    admin.nil?

  end

end
