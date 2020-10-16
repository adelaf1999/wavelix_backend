class StoreDeliveryTimeJob < Struct.new(:order_id)

  include OrderHelper

  include ProductsHelper

  def perform

    order = Order.find_by(id: order_id)

    if order.ongoing?

      order.complete!

      increment_store_balance(order)

      notify_unavailable_products(order)

    end

  end

end