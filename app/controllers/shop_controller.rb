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

            if category == nil

              products = store_user.products.where(product_available: true)

              products = products.where(stock_quantity: nil).or( products.where('stock_quantity > ?', 0) )

              products = products.where("name ILIKE ?", "%#{name}%").order('name ASC')

              products.each do |product|

                @products.push( get_product(product, customer_currency) )


              end


            else

              products = category.products.where(product_available: true)

              products = products.where(stock_quantity: nil).or( products.where('stock_quantity > ?', 0) )

              products = products.where("name ILIKE ?", "%#{name}%").order('name ASC')

              products.each do |product|

                @products.push( get_product(product, customer_currency) )


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



  def browse_category_products

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        store_user = StoreUser.find_by(id: params[:store_user_id])

        if store_user != nil

          category = store_user.categories.find_by(id: params[:category_id])

          if store_user.verified? && category != nil

            @success = true

            @products = []

            customer_currency = customer_user.default_currency

            products = category.products.where(product_available: true)

            products = products.where(stock_quantity: nil).or( products.where('stock_quantity > ?', 0) )

            products = products.order(name: :asc)

            products.each do |product|

              @products.push( get_product(product, customer_currency) )


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

            store_user.categories.where(parent_id: nil).order(name: :asc).each do |category|

              if category.subcategories.length > 0

                parent_category = traverse_subcategories(category)

                if parent_category != nil

                  @categories.push(parent_category)

                end


              else


                products = category.products.where(product_available: true)

                products = products.where(stock_quantity: nil).or( products.where('stock_quantity > ?', 0) )

                if products.length > 0

                  @categories.push({
                                       id: category.id,
                                       name: category.name,
                                       subcategories: [],
                                       parent_id: category.parent_id
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


  private

  def traverse_subcategories(category)

    subcategories = []

    parent_category = {
        id: category.id,
        name: category.name,
        parent_id: category.parent_id
    }


    category.subcategories.order(name: :asc).each do |subcategory|

      if subcategory.subcategories.length > 0

        child_category = traverse_subcategories(subcategory)

        if child_category != nil

          subcategories.push(child_category)

        end


      else

        products = subcategory.products.where(product_available: true)

        products = products.where(stock_quantity: nil).or( products.where('stock_quantity > ?', 0) )

        if products.length > 0

          subcategories.push({
                               id: subcategory.id,
                               name: subcategory.name,
                               subcategories: [],
                               parent_id: subcategory.parent_id
                           })

        end


      end

    end



    if subcategories.length > 0

      parent_category[:subcategories] = subcategories

      parent_category

    else

      nil

    end



  end

  def get_product(product, customer_currency)

    {
        id: product.id,
        name: product.name,
        picture: product.main_picture.url,
        price: convert_amount(product.price, product.currency, customer_currency),
        currency: customer_currency
    }


  end

end
