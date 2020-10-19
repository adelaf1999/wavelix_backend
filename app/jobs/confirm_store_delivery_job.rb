class ConfirmStoreDeliveryJob < Struct.new(:order_id)

  include NotificationsHelper

  def perform

    order = Order.find_by(id: order_id)

    if order.ongoing?

      # Email the customer to confirm the order if successfully received the order or to open a dispute if didnt

      OrderMailer.delay.confirm_store_delivery(order.get_customer_email, order.get_store_name, order.get_customer_name)

      send_customer_notification(
          order,
          "If you have successfully received your order from #{order.get_store_name}, please confirm the order in the orders page. Otherwise, you may open a dispute and we will investigate with the store any issues that may have occurred regarding the order.",
          'Confirm Your Order',
          {
              show_orders: true
          }
      )



    end

  end

end