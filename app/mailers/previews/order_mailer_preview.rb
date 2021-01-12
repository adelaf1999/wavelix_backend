class OrderMailerPreview < ActionMailer::Preview


  def order_canceled
    email = 'adelwaboufakher@gmail.com'
    store_name = 'Nike'
    OrderMailer.order_canceled(email, store_name)
  end

  def store_rejected_order
    email = 'adel_abouf@outlook.com'
    store_name = 'Nike'
    OrderMailer.store_rejected_order(email, store_name)
  end

  def no_drivers
    email = 'adel_abouf@outlook.com'
    store_name = 'Nike'
    OrderMailer.no_drivers(email, store_name)
  end

  def confirm_store_delivery
    email = 'adelwaboufakher@gmail.com'
    store_name = 'Nike'
    customer_name = 'Adel Abou Fakher'
    OrderMailer.confirm_store_delivery(email, store_name, customer_name)
  end

  def confirm_driver_delivery
    email = 'adelwaboufakher@gmail.com'
    store_name = 'Nike'
    customer_name = 'Adel Abou Fakher'
    OrderMailer.confirm_driver_delivery(email, store_name, customer_name)
  end


  def order_expired
    email = 'adel_abouf@outlook.com'
    store_name = 'Nike'
    OrderMailer.order_expired(email, store_name)
  end


  def order_accepted
    email = 'adelwaboufakher@gmail.com'
    store_name = 'ShopSmart'
    customer_name = 'Adel Abou Fakher'
    OrderMailer.order_accepted(email, store_name, customer_name)
  end

  def driver_assigned_order
    email = 'adelwaboufakher@gmail.com'
    customer_name = 'Adel Abou Fakher'
    OrderMailer.driver_assigned_order(email, customer_name)
  end

  def attach_order_receipt
    email = 'adelwaboufakher@gmail.com'
    customer_name = 'Adel Abou Fakher'
    OrderMailer.attach_order_receipt(email, customer_name)
  end


end