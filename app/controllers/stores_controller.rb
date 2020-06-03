class StoresController < ApplicationController

  before_action :authenticate_user!

  def get_store_currency

    if current_user.store_user?

      @store_currency = StoreUser.find_by(store_id: current_user.id).currency

    end

  end

end
