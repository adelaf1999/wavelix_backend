class StoreArrivalJob < Struct.new(:order_id)

  include OrderHelper

  def perform

    order = Order.find_by(id: order_id)

    store_fulfilled_order = order.store_fulfilled_order

    driver_arrived_to_store = order.driver_arrived_to_store

    if !driver_arrived_to_store && store_fulfilled_order

      order.update!(driver_arrived_to_store: true)

    elsif !driver_arrived_to_store && !store_fulfilled_order

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

      # Refund customer the amount he paid



    end

  end

end