module EmployeeHelper

  def username_available?(username)

    Employee.find_by(username: username).nil?

  end

end