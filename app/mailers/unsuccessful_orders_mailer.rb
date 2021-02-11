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


end