class EmployeePortalController < ApplicationController

  before_action :authenticate_employee!

  def index

    @roles = current_employee.roles

    @status = current_employee.status

  end


  def home

    store_user = current_employee.store_user

    @store = {
        name: store_user.store_name,
        logo: store_user.store.profile.profile_picture.url
    }

  end

end
