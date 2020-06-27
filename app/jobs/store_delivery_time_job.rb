class StoreDeliveryTimeJob < Struct.new(:order_id)

  include OrderHelper

  def perform

    order = Order.find_by(id: order_id)

    if order.ongoing?

      order.complete!

      increment_store_balance(order)

    end

  end

end