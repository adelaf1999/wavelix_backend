class EmployeeController < ApplicationController

  before_action :authenticate_user!

  include EmployeeHelper


  def toggle_status

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      required_params = [:employee_id]

      if required_params_valid?(required_params)

        employee = store_user.employees.find_by(id: params[:employee_id])

        if employee != nil

          if employee.inactive?

            employee.active!

          else

            employee.inactive!

          end

          # Send employee status to employee portal

          @success = true

        else

          @success = false

        end

      else

        @success = false

      end

    end

  end

  def create

    # error_codes

    # {0: USERNAME_UNAVAILABLE, 1: INVALID_PASSWORD_LENGTH}

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      required_params = [:name, :username, :password, :roles]

      if required_params_valid?(required_params)

        name = params[:name]

        username = params[:username]

        password = params[:password]

        roles = params[:roles]
        
        if username_available?(username)

          if password.length < 6

            @success = false
            @error_code = 1


          else


            begin

              roles = eval(roles)

              if roles.instance_of?(Array) && roles.size > 0

                roles = roles.map &:to_sym

                if is_roles_valid?(roles)

                  @success = true

                  Employee.create!(
                      username: username,
                      password: password,
                      name: name,
                      store_user_id: store_user.id,
                      roles: roles
                  )

                else

                  @success = false

                end


              else

                @success = false

              end

            rescue => e

              @success = false

            end






          end

        else

          @success = false
          @error_code = 0

        end




      else

        @success = false

      end


    end

  end


  private

  def is_roles_valid?(roles)

    is_valid = true


    roles.each do |role|


      if !Employee::ROLES.include?(role)

        is_valid = false

        break

      end

    end

    is_valid



  end

  def required_params_valid?(required_params)

    valid = true

    required_params.each do |p|

      if params[p] == nil || params[p].empty?

        valid = false

        break

      end

    end

    valid


  end





end
