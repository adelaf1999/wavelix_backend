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

        Admin.role_root_admins.each do |root_admin|

          if current_admin.id != root_admin.id

            notice = "#{current_admin.full_name} created an admin account for #{admin.full_name} with the following roles: #{admin.roles_text}."

            AdminAccountMailer.delay.account_created_notice(root_admin.email, notice)

          end

        end

      else

        @success = false

        @error_code = 5

        @message = 'Error creating admin account'

      end



    end

  end


  def show

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :employee_manager)

      head :unauthorized

    else

      admin = Admin.find_by(id: params[:admin_id])

      if admin != nil

        if admin.has_roles?(:root_admin)

          # Root admin account cannot be viewed by anyone

          @success = false

        elsif current_admin.has_roles?(:employee_manager) && admin.has_roles?(:employee_manager)

          # Employee managers cannot view other employee managers account

          @success = false

        elsif current_admin.id == admin.id

          @success = false

        else

          @success = true

          @admin_profile_photo = admin.profile_photo.url

          @admin_full_name = admin.full_name

          @admin_email = admin.email

          @admin_roles = admin.roles


        end

      else

        @success = false

      end


    end


  end


  def change_password

    # Error codes

    # { 0: ACCOUNT_INVALID, 1: UNAUTHORIZED_ACTION, 2: PASSWORD_ERROR }

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :employee_manager)

      head :unauthorized

    else

      admin = Admin.find_by(id: params[:admin_id])

      if admin != nil

        if admin.has_roles?(:root_admin)

          # Root admin account cannot be updated by anyone

          @success = false

          @error_code = 1

        elsif current_admin.has_roles?(:employee_manager) && admin.has_roles?(:employee_manager)

          # Employee managers cannot update other employee managers account

          @success = false

          @error_code = 1

        elsif current_admin.id == admin.id

          @success = false

          @error_code = 1

        else

          password = params[:password]

          if password.blank?

            @success = false

            @error_code = 2

            @message = 'Password cannot be empty'

          elsif password.length < 8

            @success = false

            @error_code = 2

            @message = 'Password must be at least 8 characters long'

          else

            admin.update!(password: password)

            @success = true


            Admin.role_root_admins.each do |root_admin|

              if current_admin.id != root_admin.id

                notice = "#{current_admin.full_name} has changed the password of #{admin.full_name}."

                AdminAccountMailer.delay.password_change_notice(root_admin.email, notice)


              end



            end

          end



        end

      else

        @success = false

        @error_code = 0

      end


    end


  end


  def change_roles

    # Error codes

    # { 0: ACCOUNT_INVALID, 1: UNAUTHORIZED_ACTION, 2: ROLES_ERROR }

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :employee_manager)

      head :unauthorized

    else

      admin = Admin.find_by(id: params[:admin_id])

      if admin != nil

        if admin.has_roles?(:root_admin)

          # Root admin account cannot be updated by anyone

          @success = false

          @error_code = 1

        elsif current_admin.has_roles?(:employee_manager) && admin.has_roles?(:employee_manager)

          # Employee managers cannot update other employee managers account

          @success = false

          @error_code = 1


        elsif current_admin.id == admin.id

          @success = false

          @error_code = 1

        else

          roles = params[:roles]

          if roles.blank?

            @success = false

            @error_code = 2

            @message = 'Roles cannot be empty'

          else

            begin


              roles = eval(roles)

              if roles.instance_of?(Array)

                if roles.size == 0

                  @success = false

                  @error_code = 2

                  @message = 'Please select at least one role'

                else

                  roles = roles.map &:to_sym

                  if are_roles_valid?(roles)


                    if roles.include?(:root_admin)

                      # root_admin role cannot be given by anyone, account has to be created as root_admin to receive that role

                      @success = false

                      @error_code = 2

                      @message = 'Error updating roles'


                    elsif current_admin.has_roles?(:employee_manager) &&  roles.include?(:employee_manager)

                      # Employee managers are unauthorized to give other admin accounts employee_manager role

                      @success = false

                      @error_code = 2

                      @message = 'Error updating roles'


                    else


                      admin.update!(roles: roles)

                      @success = true

                      @admin_roles = admin.roles


                      Admin.role_root_admins.each do |root_admin|

                        if current_admin.id != root_admin.id

                          notice = "#{current_admin.full_name} updated the roles of #{admin.full_name} to the following: #{admin.roles_text}."

                          AdminAccountMailer.delay.roles_changed_notice(root_admin.email, notice)

                        end

                      end


                    end



                  else

                    @success = false

                    @error_code = 2

                    @message = 'Error updating roles'

                  end


                end

              else

                @success = false

                @error_code = 2

                @message = 'Error updating roles'

              end


            rescue => e

              @success = false

              @error_code = 2

              @message = 'Error updating roles'

            end

          end


        end


      else

        @success = false

        @error_code = 0

      end


    end



  end


  def destroy


    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :employee_manager)

      head :unauthorized

    else

      admin = Admin.find_by(id: params[:admin_id])

      if admin != nil

        if admin.has_roles?(:root_admin)

          # Root admin account cannot be deleted by anyone

          @success = false

        elsif current_admin.has_roles?(:employee_manager) && admin.has_roles?(:employee_manager)

          # Employee managers cannot delete other employee managers account

          @success = false

        elsif current_admin.id == admin.id

          @success = false

        else

          admin_full_name = admin.full_name

          admin_email = admin.email

          admin.destroy!

          @success = true

          Admin.role_root_admins.each do |root_admin|

            if current_admin.id != root_admin.id

              notice = "#{current_admin.full_name} deleted the account of #{admin_full_name} with email #{admin_email}."

              AdminAccountMailer.delay.account_deleted_notice(root_admin.email, notice)

            end

          end


        end


      else

        @success = false

      end


    end



  end


  def index


    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :employee_manager)

      head :unauthorized

    else



      if current_admin.has_roles?(:root_admin)


        # Root admins can only be seen by other root admins

        # Only root admins have option to filter by root_admin role

        admins = Admin.all.order(full_name: :asc)
                     .where.not(id: current_admin.id)

        @available_roles = get_admin_roles

      else

        # Employee manager can see other employee managers

        admins = Admin.all.order(full_name: :asc)
                     .where.not(id: current_admin.id)
                     .where.not("roles ILIKE ?", "%root_admin%")

        @available_roles = get_admin_roles

        @available_roles.delete(:root_admin)


      end


      @admins = get_admin_accounts(admins)




    end


  end


  def search_admin

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :employee_manager)

      head :unauthorized

    else

      # search for admins by email or full name

      # can also filter for admin by role

      @admins = []

      search = params[:search]

      role = params[:role]

      if search != nil

        search = search.strip

        admins = Admin.all.where("email ILIKE ?", "%#{search}%").or( Admin.all.where("full_name ILIKE ?", "%#{search}%") )

        admins = admins.where.not(id: current_admin.id)

        if !role.blank?

          role = role.to_sym

          if admin_role_valid?(role)

            admins = admins.where("roles ILIKE ?", "%#{role}%")

          end

        end


        if !current_admin.has_roles?(:root_admin)

          # Root admins only appear in search results of root admin

          admins = admins.where.not("roles ILIKE ?", "%root_admin%")

        end

        admins = admins.order(full_name: :asc)

        @admins = get_admin_accounts(admins)
        


      end




    end



  end




  private


  def get_admin_accounts(admins)

    admin_accounts = []

    admins.each do |admin|

      if admin.has_roles?(:root_admin)

        admin_accounts.push({
                                profile_photo: admin.profile_photo.url,
                                full_name: admin.full_name,
                                email: nil,
                                roles: admin.roles,
                                current_sign_in_ip: nil,
                                last_sign_in_ip: nil
                            })

      else

        admin_accounts.push({
                                profile_photo: admin.profile_photo.url,
                                full_name: admin.full_name,
                                email: admin.email,
                                roles: admin.roles,
                                current_sign_in_ip: admin.current_sign_in_ip,
                                last_sign_in_ip: admin.last_sign_in_ip
                            })

      end

    end

    admin_accounts


  end



  def admin_role_valid?(role)

    available_roles = get_admin_roles

    available_roles.include?(role)

  end


  def get_admin_roles

    available_roles = Admin::ROLES

    available_roles.delete(:user)

    available_roles

  end

  def are_roles_valid?(roles)

    valid = true

    available_roles = get_admin_roles

    roles.each do |role|

      if !available_roles.include?(role)

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
