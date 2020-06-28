class PickupOrderJob < Struct.new(:order_id)

  include OrderHelper

  def perform

    order = Order.find_by(id: order_id)

    if !order.store_fulfilled_order

      get_new_driver(order)

      # Notify store that a new driver will be assigned for the order because the previous driver failed to pickup products

      # Notify driver that another driver will be assigned for the order because he failed to pickup products on time

      # Notify customer that a new driver will be assigned for the order because the previous driver failed to pickup products on time


    end


  end

end