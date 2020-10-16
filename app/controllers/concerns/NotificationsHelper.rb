module NotificationsHelper



  def send_driver_notification(order, message_body, message_title = nil, message_data = nil)

    if order.driver_id != nil

      driver = Driver.find_by(id: order.driver_id)

      customer_user = driver.customer_user

      send_push_notification(customer_user.push_token, message_body, message_title, message_data)


    end

  end

  def send_customer_notification(order, message_body, message_title = nil, message_data = nil)

    customer_user = order.customer_user

    send_push_notification(customer_user.push_token, message_body, message_title, message_data )

  end


  def send_store_notification(order, message_body, message_title = nil, message_data = nil)

    store_user = order.store_user

    send_push_notification(store_user.push_token, message_body, message_title, message_data )

    store_user.employees.each do |employee|

      if employee.has_roles?(:order_manager) && employee.active?

        send_push_notification(employee.push_token, message_body, message_title, message_data )


      end

    end


  end

  def send_push_notification(push_token, message_body, message_title = nil, message_data = nil)

    if !push_token.blank?

      message = {
          to: push_token,
          sound: 'default',
          body: message_body,
          channelId: 'default',
          priority: 'high'
      }

      if message_title != nil

        message[:title] = message_title

      end

      if message_data != nil

        message[:data] = message_data

      end

      messages = [message]

      PushNotificationJob.perform_later(messages)

      true

    else

      false

    end

  end

end