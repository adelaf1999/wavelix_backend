class DeliverOrderJob < Struct.new(:order_id)

  include OrderHelper

  def perform

    order = Order.find_by(id: order_id)

    if !order.driver_fulfilled_order

      order.canceled!

      order.update!(order_canceled_reason: 'Driver did not deliver product(s) to customer')

      store_user = StoreUser.find_by(id: order.store_user_id)

      orders = get_store_orders(store_user)

      ActionCable.server.broadcast "orders_channel_#{order.store_user_id}", {orders: orders}

      # Send orders to customer_user channel

      # Send orders to driver channel

      # Notify store that order was canceled and driver has been requested to return products to store

      # Request driver to return products to store

      # Notify customer that the order has been canceled and that he will be refunded the full amount paid

      # Refund customer the amount he paid


    end


  end


end