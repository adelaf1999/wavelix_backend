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

  def notify_admin_unconfirmed_order(email, admin_name, order_id)
    @admin_name = admin_name
    @view_order_link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/unconfirmed-orders/order_id=#{order_id}"
    mail to: email, subject: 'Unconfirmed Order'
  end


  def notify_admin_order_canceled(email, admin_name, customer_name, store_name, order_id)
    @admin_name = admin_name
    @customer_name = customer_name
    @store_name = store_name
    @link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/orders/order_id=#{order_id}"
    mail to: email, subject: 'Unconfirmed Order Canceled'
  end

end