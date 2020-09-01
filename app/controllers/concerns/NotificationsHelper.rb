module NotificationsHelper

  def send_push_notification(push_token, message_body, message_title = nil)

    if !push_token.blank?

      client = Exponent::Push::Client.new

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

      messages = [message]

      client.send_messages(messages)

      true

    else

      false

    end

  end

end