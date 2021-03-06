module Previews

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

    def notify_admin_unconfirmed_order
      email = 'adelwaboufakher@gmail.com'
      admin_name = 'Adel Abou Fakher'
      order_id = 1
      UnconfirmedOrderMailer.notify_admin_unconfirmed_order(email, admin_name, order_id)
    end


    def notify_admin_order_canceled
      email = 'adelwaboufakher@gmail.com'
      admin_name = 'Wajih Abou Fakher'
      customer_name = 'Adel Abou Fakher'
      store_name = 'ShopSmart'
      order_id = 1
      UnconfirmedOrderMailer.notify_admin_order_canceled(email, admin_name, customer_name, store_name, order_id)
    end


  end

end

