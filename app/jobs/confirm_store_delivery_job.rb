class ConfirmStoreDeliveryJob < Struct.new(:order_id)

  include NotificationsHelper

  def perform

    order = Order.find_by(id: order_id)

    if order.ongoing?

      OrderMailer.delay.confirm_store_delivery(order.get_customer_email, order.get_store_name, order.get_customer_name)

      send_customer_notification(
          order,
          "If you have successfully received your order from #{order.get_store_name}, please confirm the order in the orders page. Otherwise, we will contact the store to find out if any issues have occurred with your order and let you know.",
          'Confirm Your Order',
          {
              show_orders: true
          }
      )

      ActionCable.server.broadcast 'unconfirmed_orders_channel', {
          new_unconfirmed_order: true
      }



    end

  end

end