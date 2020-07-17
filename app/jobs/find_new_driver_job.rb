class FindNewDriverJob < ApplicationJob

  queue_as :find_new_driver_queue

  include OrderHelper

  def perform(order_id)

    order = Order.find_by(id: order_id)

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