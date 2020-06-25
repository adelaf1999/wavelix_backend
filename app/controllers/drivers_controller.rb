class DriversController < ApplicationController

  include OrderHelper

  before_action :authenticate_user!

  def decline_order_request

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      current_driver = customer_user.driver

      if current_driver != nil

        order = Order.find_by(id: params[:order_id])

        if order != nil

          drivers_rejected = order.drivers_rejected.map(&:to_i)

          unconfirmed_drivers = order.unconfirmed_drivers.map(&:to_i)

          if order.pending? && order.driver_id == nil && order.prospective_driver_id == current_driver.id && !drivers_rejected.include?(current_driver.id)

            @success = true

            if unconfirmed_drivers.include?(current_driver.id)

              unconfirmed_drivers.delete(current_driver.id)

              order.update!(unconfirmed_drivers: unconfirmed_drivers)

            end

            drivers_rejected.push(current_driver.id)

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



          else

            @success = false

          end

        else

          @success = false

        end

      else

        @success = false

      end

    end

  end

end
