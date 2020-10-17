class OrderMailer < ApplicationMailer

  def order_canceled(email, store_name)
    @store_name = store_name
    mail to: email, subject: 'Order Canceled Successfully'
  end

  def store_rejected_order(email, store_name)
    @store_name = store_name
    mail to: email, subject: "Order rejected by #{store_name}"
  end

end
