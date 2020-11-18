class EmployeeOrdersChannel < ApplicationCable::Channel


  def start_stream(current_employee)

    if current_employee.has_roles?(:order_manager)

      stream_from "employee_orders_channel_#{current_employee.id}"

    else

      reject

    end

  end

  def subscribed

    if current_employee.blank?

      access_token = params[:access_token]

      client = params[:client]

      uid = params[:uid]

      employee = Employee.find_by_uid(uid)

      if employee != nil && employee.valid_token?(access_token, client)

        start_stream(employee)

      else

        reject

      end

    else

      start_stream(current_employee)

    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end