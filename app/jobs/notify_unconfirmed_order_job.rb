class NotifyUnconfirmedOrderJob < Struct.new(:order_id)

  def perform

    order = Order.find_by(id: order_id)

    if order.ongoing?

      admins = Admin.role_root_admins + Admin.role_order_managers

      admins = admins.uniq

      admins.each do |admin|

        email = admin.email

        admin_name = admin.full_name

        UnconfirmedOrderMailer.delay.notify_admin_unconfirmed_order(email, admin_name, order.id)

      end

    end

  end

end