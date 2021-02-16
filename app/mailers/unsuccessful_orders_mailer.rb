class UnsuccessfulOrdersMailer < ApplicationMailer


  def captured_cost_driver_balance(email, driver_name, customer_name, store_name)
    @driver_name = driver_name
    @customer_name = customer_name
    @store_name = store_name
    mail to: email, subject: 'Order Canceled'
  end


  def recovered_cost_driver_balance(email, customer_name, driver_name)
    @customer_name = customer_name
    @driver_name = driver_name
    mail to: email, subject: 'Order Canceled'
  end


  def partial_recover_driver_balance(email, customer_name, driver_name, amount, currency)
    @customer_name = customer_name
    @driver_name = driver_name
    @amount = amount
    @currency = currency
    mail to: email, subject: 'Order Canceled'
  end


  def no_recovery_driver_balance(email, customer_name, driver_name)
    @customer_name = customer_name
    @driver_name = driver_name
    mail to: email, subject: 'Order Canceled'
  end


  def refund_issued_customer(email, store_name, customer_name)
    @store_name = store_name
    @customer_name = customer_name
    mail to: email, subject: 'Order Canceled'
  end


  def new_unsuccessful_order(email, admin_name, driver_id)
    @admin_name = admin_name
    @link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/unsuccessful-orders/driver_id=#{driver_id}"
    mail to: email, subject: 'Unsuccessful Order'
  end

  def unresolved_order(email, admin_name, driver_id, days_left)
    @admin_name = admin_name
    @link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/unsuccessful-orders/driver_id=#{driver_id}"
    @days_left = days_left
    mail to: email, subject: 'Unresolved Order'
  end


  def notify_admin_order_canceled(email, admin_name, customer_name, store_name, order_id)
    @admin_name = admin_name
    @customer_name = customer_name
    @store_name = store_name
    @link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/orders/order_id=#{order_id}"
    mail to: email, subject: 'Unsuccessful Order Canceled'
  end


  def incomplete_order_recovery(email, admin_name, customer_name, store_name, order_id)
    @admin_name = admin_name
    @customer_name = customer_name
    @store_name = store_name
    @link = "#{Rails.env.development?  ? ENV.fetch('DEVELOPMENT_ADMIN_WEBSITE_URL') : ENV.fetch('PRODUCTION_ADMIN_WEBSITE_URL') }/orders/order_id=#{order_id}"
    mail to: email, subject: 'Unsuccessful Order Incomplete Recovery'
  end


end