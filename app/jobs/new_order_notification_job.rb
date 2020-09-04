class NewOrderNotificationJob < ApplicationJob

  queue_as :new_order_notification_queue

  include NotificationsHelper

  def perform(order_id)

    order = Order.find_by(id: order_id)

    if order != nil

      send_store_notification(
          order,
          'A customer has just placed a new order',
          nil,
          {
              show_orders: true
          }
      )


    end



  end

end