class ShopController < ApplicationController


  before_action :authenticate_user!

  include OrderHelper


  def search_shop_products

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        store_user = StoreUser.find_by(id: params[:store_user_id])

        name = params[:name]

        if store_user != nil && name != nil

          if store_user.verified?

            @success = true

            @products = []

            category = store_user.categories.find_by(id: params[:category_id])

            customer_currency = customer_user.default_currency

            name = name.strip
            
            if !name.blank?


              if category == nil

                products = store_user.products.where(product_available: true)

                products = products.where(stock_quantity: nil).or( products.where('stock_quantity > ?', 0) )

                products = products.where("name ILIKE ?", "%#{name}%").order('name ASC')

                products.each do |product|

                  @products.push({
                                     id: product.id,
                                     name: product.name,
                                     picture: product.main_picture.url,
                                     price: convert_amount(product.price, product.currency, customer_currency),
                                     currency: customer_currency
                                 })


                end


              else

                products = category.products.where(product_available: true)

                products = products.where(stock_quantity: nil).or( products.where('stock_quantity > ?', 0) )

                products = products.where("name ILIKE ?", "%#{name}%").order('name ASC')

                products.each do |product|

                  @products.push({
                                     id: product.id,
                                     name: product.name,
                                     picture: product.main_picture.url,
                                     price: convert_amount(product.price, product.currency, customer_currency),
                                     currency: customer_currency
                                 })


                end

              end

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


    else

      @success = false

    end

  end


  def index


    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        store_user = StoreUser.find_by(id: params[:store_user_id])

        if store_user != nil

          if store_user.verified?

            @success = true

            @store_name = store_user.store_name

            @categories = []

            store_user.categories.order(name: :asc).each do |category|

              products = category.products.where(product_available: true)

              products = products.where(stock_quantity: nil).or( products.where('stock_quantity > ?', 0) )

              if products.length > 0

                @categories.push({ id: category.id, name: category.name })

              end

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

    else

      @success = false

    end

  end

end
