class StoreDeliveryTimeJob < Struct.new(:order_id)

  def perform

    order = Order.find_by(id: order_id)

    if order.ongoing?

      order.complete!

       # Increment store balance by looping on each ordered product and multiplying price by quantity

      increment = 0

      order.products.each do |ordered_product|

        # The currency of the ordered_products is the same as the store user balance currency

        ordered_product = eval(ordered_product)

        increment += ordered_product[:price] * ordered_product[:quantity]

      end

      store_user = StoreUser.find_by(id: order.store_user_id)

      store_user.increment!(:balance, increment)


    end

  end

end