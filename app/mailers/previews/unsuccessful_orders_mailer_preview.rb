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

end