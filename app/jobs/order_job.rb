class OrderJob < Struct.new(:order_id, :driver_id)

  include OrderHelper

  def perform

    order = Order.find_by(id: order_id)

    drivers_rejected = order.drivers_rejected.map(&:to_i)

    unconfirmed_drivers = order.unconfirmed_drivers.map(&:to_i)

    if order.pending? && order.driver_id == nil && order.prospective_driver_id == driver_id && !drivers_rejected.include?(driver_id)


      store_user = StoreUser.find_by(id: order.store_user_id)

      has_sensitive_products = store_user.has_sensitive_products

      store_location = store_user.store_address

      store_latitude = store_location[:latitude]

      store_longitude = store_location[:longitude]


      if !unconfirmed_drivers.include?(driver_id)

        unconfirmed_drivers.push(driver_id)

        order.update!(unconfirmed_drivers: unconfirmed_drivers)

      end

      if has_sensitive_products

        drivers_has_sensitive_products(order, store_user, store_latitude, store_longitude)

      else

        if order.exclusive?

          drivers_exclusive_delivery(order, store_user, store_latitude, store_longitude)

        else



        end

      end



    end

  end

end