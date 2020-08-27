class EmployeePortalController < ApplicationController

  before_action :authenticate_employee!

  def index

    @roles = current_employee.roles

    @status = current_employee.status

  end

end
