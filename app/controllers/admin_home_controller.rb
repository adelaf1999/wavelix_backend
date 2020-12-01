class AdminHomeController < ApplicationController

  include AdminHelper

  before_action :authenticate_admin!

  # This controller includes actions that can be accessed by any admin with any role(s)

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    else


      @profile_photo = current_admin.profile_photo.url

      @name = current_admin.full_name

      @email = current_admin.email

      @roles = current_admin.roles


    end


  end



end
