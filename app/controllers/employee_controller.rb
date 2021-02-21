class EmployeeController < ApplicationController

  before_action :authenticate_user!

  include EmployeeHelper


  def search

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      search = params[:search]

      if search != nil

        @success = true

        @employees = []

        employees = store_user.employees

        employee_ids = []



        employees_by_name = employees.where("name ILIKE ?", "%#{search}%")

        employees_by_name.each do |employee|

          employee_ids.push(employee.id)

        end


        employees_by_username = employees.where("username ILIKE ?", "%#{search}%" )

        employees_by_username.each do |employee|

          employee_ids.push(employee.id)

        end


        employee_ids.uniq!


        searched_employees = employees.where(id: employee_ids)

        searched_employees.order(name: :asc).each do |employee|

          @employees.push(get_store_employee(employee))

        end




      else

        @success = false

      end


    end

  end

  def update_roles

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      required_params = [:roles, :employee_id]

      if required_params_valid?(required_params)

        employee = store_user.employees.find_by(id: params[:employee_id])

        if employee != nil

          roles = params[:roles]

          begin

            roles = eval(roles)

            if roles.instance_of?(Array) && roles.size > 0

              roles = roles.map &:to_sym

              if is_roles_valid?(roles)

                employee.update!(roles: roles)

                @success = true

                @employees = get_store_employees(store_user)

                ActionCable.server.broadcast "employee_channel_#{employee.id}", {
                    roles: roles
                }

              else

                @success = false

              end


            else

              @success = false

            end

          rescue => e

            @success = false

          end

        else

          @success = false

        end

      else

        @success = false

      end


    end

  end


  def change_password

    # error_codes

    # {0: INVALID_PASSWORD_LENGTH }

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      required_params = [:password, :employee_id]

      if required_params_valid?(required_params)

        employee = store_user.employees.find_by(id: params[:employee_id])

        if employee != nil

          password = params[:password]

          if password.length < 8

            @success = false
            @error_code = 0

          else

            @success = true
            employee.update!(password: password)


          end


        else

          @success = false

        end

      else

        @success = false

      end



    end

  end


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

          @employees = get_store_employees(store_user)

          ActionCable.server.broadcast "employee_channel_#{employee.id}", {
              status: employee.status
          }

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

          if password.length < 8

            @success = false
            @error_code = 1


          else


            begin

              roles = eval(roles)

              if roles.instance_of?(Array) && roles.size > 0

                roles = roles.map &:to_sym

                if is_roles_valid?(roles)

                  Employee.create!(
                      username: username,
                      password: password,
                      name: name,
                      store_user_id: store_user.id,
                      roles: roles
                  )


                  @success = true

                  @employees = get_store_employees(store_user)


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


  def index

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      @roles = {
          :product_manager => 'Employee will be able to manage categories and products',
          :order_manager => 'Employee will be able to manage orders'
      }

      @employees = get_store_employees(store_user)


    end

  end


  private


  def get_store_employees(store_user)

    employees = []

    store_user.employees.order(name: :asc).each do |employee|

      employees.push(get_store_employee(employee))

    end

    employees

  end


  def get_store_employee(employee)

    {
        name: employee.name,
        username: employee.username,
        status: employee.status,
        roles: employee.get_roles,
        id: employee.id
    }

  end

  def is_roles_valid?(roles)

    is_valid = true


    roles.each do |role|


      valid_roles = Employee::ROLES

      valid_roles.delete(:user)

      if !valid_roles.include?(role)

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
