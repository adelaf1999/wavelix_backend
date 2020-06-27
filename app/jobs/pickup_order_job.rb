class PickupOrderJob < Struct.new(:order_id)

  include OrderHelper

  def perform

    order = Order.find_by(id: order_id)

    if !order.store_fulfilled_order

      order.canceled!

      order.products.each do |ordered_product|

        ordered_product = eval(ordered_product)

        product = Product.find_by(id: ordered_product[:id])

        if (product != nil) && (product.stock_quantity != nil)

          stock_quantity = product.stock_quantity + ordered_product[:quantity]

          product.update!(stock_quantity: stock_quantity)

        end

      end

      order.update!(order_canceled_reason: 'Order was not fulfilled')

      store_user = StoreUser.find_by(id: order.store_user_id)

      orders = get_store_orders(store_user)

      ActionCable.server.broadcast "orders_channel_#{order.store_user_id}", {orders: orders}

      # Send orders to customer_user channel

      # Send push notification to  customer/store/driver

      # Notify store that order was canceled and not to fulfill the order anymore

      # Notify driver that order was canceled

      # Notify customer that the order has been canceled and that he will be refunded the full amount paid

      # Refund customer the amount he paid


    end


  end

end