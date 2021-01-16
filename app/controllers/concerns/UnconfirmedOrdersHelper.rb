module UnconfirmedOrdersHelper

  def is_order_unconfirmed?(order)

    time_exceeded = order.delivery_time_limit <= DateTime.now.utc

    order.ongoing? && order.store_handles_delivery && order.store_accepted? && time_exceeded

  end

end