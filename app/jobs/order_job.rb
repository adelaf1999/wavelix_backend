class OrderJob < Struct.new(:order_id)


  def perform

    order = Order.find_by(id: order_id)

    if order.pending?

      # If the order was pending the stock quantity will be re-incremented

      # And the order will be marked canceled

      ordered_products = order.products

      ordered_products.each do |ordered_product|

        ordered_product = eval(ordered_product)

        product = Product.find_by(id: ordered_product[:id])

        stock_quantity = product.stock_quantity + ordered_product[:quantity]

        product.update!(stock_quantity: stock_quantity)

      end

      order.canceled!


    end

  end

end