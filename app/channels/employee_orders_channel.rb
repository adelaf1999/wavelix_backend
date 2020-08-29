class EmployeeOrdersChannel < ApplicationCable::Channel

  def subscribed

    if current_employee.blank?

      reject

    else

      if current_employee.has_roles?(:order_manager)

        stream_from "employee_orders_channel_#{current_employee.id}"

      else

        reject

      end



    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end