class NotifyUnsuccessfulOrderJob < Struct.new(:order_id)

  include UnsuccessfulOrdersHelper

  def perform

    order = Order.find_by(id: order_id)

    driver_id = order.driver_id

    if is_order_unsuccessful?(order)

      admins = Admin.role_root_admins + Admin.role_order_managers

      admins = admins.uniq

      admins.each do |admin|

        email = admin.email

        admin_name = admin.full_name

        UnsuccessfulOrdersMailer.delay.new_unsuccessful_order(email, admin_name, driver_id)

      end

    end


  end


end