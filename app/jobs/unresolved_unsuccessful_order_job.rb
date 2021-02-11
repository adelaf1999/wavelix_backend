class UnresolvedUnsuccessfulOrderJob < Struct.new(:order_id)

  include UnsuccessfulOrdersHelper

  def perform

    order = Order.find_by(id: order_id)

    driver_id = order.driver_id

    if is_order_unsuccessful?(order)

      resolve_time_limit = order.resolve_time_limit

      days_left = ( (resolve_time_limit - DateTime.now.utc) / 86400 ).round


      admins = Admin.role_root_admins + Admin.role_order_managers

      admins = admins.uniq

      admins.each do |admin|

        email = admin.email

        admin_name = admin.full_name

        UnsuccessfulOrdersMailer.delay.unresolved_order(email, admin_name, driver_id, days_left)

      end



    end

  end

end