class UnconfirmedOrdersController < ApplicationController

  include AdminHelper

  before_action :authenticate_admin!

  def index

    if is_admin_session_expired?(current_admin)

      head 440

    elsif !current_admin.has_roles?(:root_admin, :order_manager)

      head :unauthorized

    else

      @unconfirmed_orders = []

      unconfirmed_orders = Order.all.where(status: 2, store_handles_delivery: true, store_confirmation_status: 2).where('delivery_time_limit <= ?', DateTime.now.utc)

      unconfirmed_orders.each do |order|

        @unconfirmed_orders.push({
                                    id: order.id,
                                    store_name: order.get_store_name,
                                    customer_name: order.get_customer_name,
                                    country: order.get_country_name,
                                    ordered_at: order.created_at,
                                    delivery_time_limit: order.delivery_time_limit
                                 })

      end

    end

  end


end
