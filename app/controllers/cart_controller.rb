class CartController < ApplicationController

  before_action :authenticate_user!

  include OrderHelper


  def add

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      cart = customer_user.cart

      product = Product.find_by(id: params[:product_id])

      if product != nil

        if customer_user.country == product.store_country

          quantity = params[:quantity]

          if quantity != nil

            res = /^(?<num>\d+)$/.match(quantity)

            if res == nil || quantity.to_i == 0

              @success = false

            else

              quantity = quantity.to_i

              product_options = params[:product_options] # optional can be nil/empty

              if product_options != nil && !product_options.empty?

                product_options = eval(product_options)

                if !product_options.instance_of?(Hash) || product_options.size == 0

                  product_options = nil

                end

              else

                product_options = nil

              end

              @success = true

              store_user = product.category.store_user

              CartItem.create!(
                  product_id: product.id,
                  quantity: quantity,
                  product_options: product_options,
                  cart_id: cart.id,
                  store_user_id: store_user.id
              )


            end


          else

            @success = false

          end



        else

          @success = false

        end



      else

        @success = false

      end


    end

  end


  private

  def is_number?(arg)

    arg.is_a?(Numeric)

  end

end
