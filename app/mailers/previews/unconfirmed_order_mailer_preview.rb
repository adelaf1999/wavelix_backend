class UnconfirmedOrderMailerPreview < ActionMailer::Preview

  def notify_customer_order_canceled
    email = 'adelwaboufakher@gmail.com'
    customer_name = 'Adel Abou Fakher'
    store_name = 'Nike'
    UnconfirmedOrderMailer.notify_customer_order_canceled(email, customer_name, store_name)
  end

  def notify_store_order_canceled
    email = 'adelwaboufakher@gmail.com'
    customer_name = 'Adel Abou Fakher'
    UnconfirmedOrderMailer.notify_store_order_canceled(email, customer_name)
  end

end