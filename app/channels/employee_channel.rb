class EmployeeChannel <  ApplicationCable::Channel

  def subscribed

    if current_employee.blank?

      reject

    else

      stream_from "employee_channel_#{current_employee.id}"


    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end