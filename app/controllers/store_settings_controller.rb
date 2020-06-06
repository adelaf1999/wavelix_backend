class StoreSettingsController < ApplicationController

  before_action :authenticate_user!

  def toggle_handles_delivery

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      if store_user.handles_delivery

        handles_delivery = false

        store_user.update!(handles_delivery: handles_delivery, maximum_delivery_distance: nil)

      else

        handles_delivery = true

        store_user.update!(handles_delivery: handles_delivery)

      end


    end

  end

  def index

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)


      if store_user.maximum_delivery_distance == nil

        @maximum_delivery_distance = ''

      else

        @maximum_delivery_distance = store_user.maximum_delivery_distance

      end



      @handles_delivery = store_user.handles_delivery

      @status = store_user.status

      @location = store_user.store_address


    end

  end

  def set_maximum_delivery_distance

    # Allows stores that handle delivery to set maximum delivery distance

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      if store_user.handles_delivery

        distance = params[:distance]

        if distance == nil || distance == ''

          @success = true

          store_user.update!(maximum_delivery_distance: nil)

        else


          # Distance must be a decimal greater than 0

          if is_delivery_distance_valid?(distance)

            @success = true

            distance = distance.to_d

            store_user.update!(maximum_delivery_distance: distance)


          else

            @success = false

          end


        end

      end


    end

  end

  private

  def is_delivery_distance_valid?(distance)

    res = /^\d+([.]\d+)?$/.match(distance)

    if res == nil

      false

    else

      distance = distance.to_d

      if distance == 0

        false

      else

        true

      end

    end


  end



end
