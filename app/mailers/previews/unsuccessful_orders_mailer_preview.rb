class UnsuccessfulOrdersMailerPreview <  ActionMailer::Preview

  def captured_cost_driver_balance
    email = 'adelwaboufakher@gmail.com'
    driver_name = 'Wajih Abou Fakher'
    customer_name = 'Adel Abou Fakher'
    store_name = 'ShopSmart'
    UnsuccessfulOrdersMailer.captured_cost_driver_balance(email, driver_name, customer_name, store_name)
  end

  def recovered_cost_driver_balance
    email = 'adelwaboufakher@gmail.com'
    customer_name = 'Adel Abou Fakher'
    driver_name = 'Wajih Abou Fakher'
    UnsuccessfulOrdersMailer.recovered_cost_driver_balance(email, customer_name, driver_name)
  end

  def partial_recover_driver_balance
    email = 'adelwaboufakher@gmail.com'
    customer_name = 'Adel Abou Fakher'
    driver_name = 'Wajih Abou Fakher'
    amount = '25'
    currency = 'USD'
    UnsuccessfulOrdersMailer.partial_recover_driver_balance(email, customer_name, driver_name, amount, currency)
  end

  def no_recovery_driver_balance
    email = 'adelwaboufakher@gmail.com'
    customer_name = 'Adel Abou Fakher'
    driver_name = 'Wajih Abou Fakher'
    UnsuccessfulOrdersMailer.no_recovery_driver_balance(email, customer_name, driver_name)
  end

  def refund_issued_customer
    email = 'adelwaboufakher@gmail.com'
    store_name = 'ShopSmart'
    customer_name = 'Adel Abou Fakher'
    UnsuccessfulOrdersMailer.refund_issued_customer(email, store_name, customer_name)
  end

  def new_unsuccessful_order
    email = 'adelwaboufakher@gmail.com'
    admin_name = 'Adel Abou Fakher'
    driver_id = 3
    UnsuccessfulOrdersMailer.new_unsuccessful_order(email, admin_name, driver_id)
  end

  def unresolved_order
    email = 'adelwaboufakher@gmail.com'
    admin_name = 'Adel Abou Fakher'
    driver_id = 3
    days_left = 5
    UnsuccessfulOrdersMailer.unresolved_order(email, admin_name, driver_id, days_left)
  end

  def notify_admin_order_canceled
    email = 'adelwaboufakher@gmail.com'
    admin_name = 'Wajih Abou Fakher'
    customer_name = 'Adel Abou Fakher'
    store_name = 'ShopSmart'
    order_id = 1
    UnsuccessfulOrdersMailer.notify_admin_order_canceled(email, admin_name, customer_name, store_name, order_id)
  end


  def incomplete_order_recovery
    email = 'adelwaboufakher@gmail.com'
    admin_name = 'Adel Abou Fakher'
    customer_name = 'Wajih Abou Fakher'
    store_name = 'ShopSmart'
    order_id = 1
    UnsuccessfulOrdersMailer.incomplete_order_recovery(email, admin_name, customer_name, store_name, order_id)
  end


end