class OrderRequest < ApplicationRecord

  enum order_type: { standard: 0, exclusive: 1 } # Can be nil if store handles delivery

  serialize :delivery_location, Hash



  def get_ordered_products

    ordered_products_ids = self.products.map(&:to_i)

    OrderedProduct.where(id: ordered_products_ids)

  end



  def self.create_order(order_request, payment_intent_id)

    if Order.find_by(order_request_id: order_request.id) == nil

      order = Order.new

      order.stripe_payment_intent = payment_intent_id

      order.order_request_id = order_request.id

      order.products = order_request.products

      order.delivery_location = order_request.delivery_location


      store_user_id = order_request.store_user_id

      customer_user_id = order_request.customer_user_id


      order.store_user_id = store_user_id

      order.customer_user_id = customer_user_id


      order.store_name = StoreUser.find_by(id: store_user_id).store_name

      order.customer_name = CustomerUser.find_by(id: customer_user_id).full_name


      order.country = order_request.country

      order.store_handles_delivery = order_request.store_handles_delivery

      order.total_price = order_request.total_price

      order.total_price_currency = order_request.total_price_currency

      order.order_type = order_request.order_type

      order.delivery_fee = order_request.delivery_fee

      order.delivery_fee_currency = order_request.delivery_fee_currency


      order_request.get_ordered_products.each do |ordered_product|

        product = Product.find_by(id: ordered_product.product_id)

        if (product != nil) && (product.stock_quantity != nil)

          # If the stock quantity of a product was not nil it will be decremented after an order is created

          stock_quantity = product.stock_quantity - ordered_product.quantity

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
