class PushNotificationJob < ApplicationJob

  queue_as :push_notification_queue

  def perform(messages)

    client = Exponent::Push::Client.new

    client.send_messages(messages)

  end


end