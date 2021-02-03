class OrderJob < Struct.new(:order_id, :driver_id)

  include OrderHelper

  def perform

    order = Order.find_by(id: order_id)

    drivers_rejected = order.get_drivers_rejected

    if order.pending? && order.driver_id == nil && order.prospective_driver_id == driver_id && !drivers_rejected.include?(driver_id)


      driver = Driver.find_by(id: driver_id)

      ActionCable.server.broadcast "driver_channel_#{driver.customer_user_id}", {
          contacting_driver: false
      }

      drivers_rejected.push(driver_id)

      order.update!(drivers_rejected: drivers_rejected)


      store_user = StoreUser.find_by(id: order.store_user_id)

      has_sensitive_products = store_user.has_sensitive_products

      store_location = store_user.store_address

      store_latitude = store_location[:latitude]

      store_longitude = store_location[:longitude]


      if has_sensitive_products

        drivers_has_sensitive_products(order, store_user, store_latitude, store_longitude)

      else

        if order.exclusive?

          drivers_exclusive_delivery(order, store_user, store_latitude, store_longitude)

        else

          drivers_standard_delivery(order, store_user, store_latitude, store_longitude)

        end

      end


    end

  end

end