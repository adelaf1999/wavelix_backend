class ProfileController < ApplicationController

  before_action :authenticate_user!

  def view_my_profile

    if current_user.store_user?

      @profile_data = {}
      store_user = StoreUser.find_by(store_id: current_user.id)
      @profile_data[:store_name] = store_user.store_name
      @profile_data[:store_address] = store_user.store_address
      @profile_data[:store_number] = store_user.store_number
      profile = current_user.profile
      @profile_data[:profile] = profile
      @profile_data = @profile_data.to_json


    else

    end


  end


end
