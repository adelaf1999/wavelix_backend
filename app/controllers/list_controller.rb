class ListController < ApplicationController

  before_action :authenticate_user!

  include ValidationsHelper

  include OrderHelper

  def create

    if current_user.store_user?

      head :unauthorized

      return

    else

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

    name = params[:name]

    privacy = params[:privacy]

    if !name.blank? && !privacy.blank?

      name = name.strip

      if is_privacy_valid?(privacy)

        privacy = privacy.to_i

        List.create!(name: name, privacy: privacy, customer_user_id: customer_user.id)

        @success = true

        @lists = customer_user_lists(customer_user)



      else

        @success =  false

      end





    else

      @success =  false

    end


  end


  private

  def customer_user_lists(customer_user)

    lists = []

    customer_currency = customer_user.default_currency

    customer_user.lists.order(name: :asc).each do |list|


      products = []

      list.list_products.each do |list_product|

        product = Product.find_by(id: list_product.product_id)

        if product != nil

          # sanity check

          if product.product_available

            products.push({
                              name: product.name,
                              price: convert_amount(product.price, product.currency, customer_currency),
                              currency: customer_currency,
                              picture: product.main_picture.url
                          })

          end

        end

      end

      products = products.sort_by { |item| item.name }



      lists.push({
                     id: list.id,
                     name: list.name,
                     privacy: list.privacy,
                     is_default: list.is_default,
                     products: products
                 })






    end

    lists

  end


  def is_privacy_valid?(privacy)

    if is_whole_number?(privacy)

      privacy = privacy.to_i

      [0, 1].include?(privacy)

    else

      false

    end

  end


end
