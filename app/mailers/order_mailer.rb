class OrderMailer < ApplicationMailer

  def order_canceled(email, store_name)
    @store_name = store_name
    mail to: email, subject: 'Order Canceled Successfully'
  end

  def store_rejected_order(email, store_name)
    @store_name = store_name
    mail to: email, subject: "Order rejected by #{store_name}"
  end

  def no_drivers(email, store_name)
    @store_name = store_name
    mail to: email, subject: 'Order Canceled'
  end

  def confirm_store_delivery(email, store_name, customer_name)
    @store_name = store_name
    @customer_name = customer_name
    mail to: email, subject: 'Confirm Your Order'
  end

  def confirm_driver_delivery(email, store_name, customer_name)
    @store_name = store_name
    @customer_name = customer_name
    mail to: email, subject: 'Confirm Your Order'
  end


  def order_expired(email, store_name)
    @store_name = store_name
    mail to: email, subject: "Order from #{store_name} has expired"
  end

  def order_accepted(email, store_name, customer_name)
    @store_name = store_name
    @customer_name = customer_name
    mail to: email, subject: "Order Accepted by #{store_name}"
  end

end
