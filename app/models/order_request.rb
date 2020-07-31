class OrderRequest < ApplicationRecord

  enum order_type: { standard: 0, exclusive: 1 } # Can be nil if store handles delivery

  serialize :delivery_location, Hash


  def self.create_order(order_request, payment_intent_id)

    if Order.find_by(order_request_id: order_request.id) == nil

      order = Order.new


      order.stripe_payment_intent = payment_intent_id

      order.order_request_id = order_request.id

      order.products = order_request.products

      order.delivery_location = order_request.delivery_location

      order.store_user_id = order_request.store_user_id

      order.customer_user_id = order_request.customer_user_id

      order.country = order_request.country

      order.store_handles_delivery = order_request.store_handles_delivery

      order.total_price = order_request.total_price

      order.total_price_currency = order_request.total_price_currency

      order.order_type = order_request.order_type

      order.delivery_fee = order_request.delivery_fee

      order.delivery_fee_currency = order_request.delivery_fee_currency

      order_request.products.each do |ordered_product|

        ordered_product = eval(ordered_product)

        product = Product.find_by(id: ordered_product[:id])

        if (product != nil) && (product.stock_quantity != nil)

          # If the stock quantity of a product was not nil it will be decremented after an order is created

          stock_quantity = product.stock_quantity - ordered_product[:quantity]

          product.update!(stock_quantity: stock_quantity)

        end

      end

      order.save!

      true


    else


      false

    end


  end



end
