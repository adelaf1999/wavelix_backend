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

end