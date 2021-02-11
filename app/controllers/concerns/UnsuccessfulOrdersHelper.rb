module UnsuccessfulOrdersHelper

  def is_order_unsuccessful?(order)

    order.ongoing? &&
        order.store_accepted? &&
        !order.store_handles_delivery &&
        order.store_fulfilled_order &&
        !order.driver_fulfilled_order &&
        ( order.delivery_time_limit <= DateTime.now.utc )

  end

end