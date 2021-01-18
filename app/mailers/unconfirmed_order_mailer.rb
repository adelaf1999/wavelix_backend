class UnconfirmedOrderMailer < ApplicationMailer

  def notify_customer_order_canceled(email, customer_name, store_name)
    @customer_name = customer_name
    @store_name = store_name
    mail to: email, subject: "Your order from #{store_name} has been canceled"
  end

  def notify_store_order_canceled(email, customer_name)
    @customer_name = customer_name
    mail to: email, subject: "The order of your customer #{customer_name} has been canceled"
  end

end