module ApplicationCable
  class Connection < ActionCable::Connection::Base

    identified_by :current_user
    identified_by :current_employee

    def connect
      self.current_user = find_user
      self.current_employee = find_employee
    end

    private

    def find_employee

      employee = Employee.find_by(id: cookies.encrypted[:employee_id])

      if employee != nil

        employee

      end


    end




    def find_user

      user = User.find_by(id: cookies.encrypted[:user_id])

      if user != nil
        user
      end

    end




  end
end
