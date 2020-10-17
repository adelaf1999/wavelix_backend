class OrderMailerPreview < ActionMailer::Preview


  def order_canceled
    email = 'adelwaboufakher@gmail.com'
    store_name = 'Nike'
    OrderMailer.order_canceled(email, store_name)
  end

end