class OrderMailer < ApplicationMailer

  def order_canceled(email, store_name)
    @store_name = store_name
    mail to: email, subject: 'Order Canceled Successfully'
  end

end
