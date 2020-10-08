module ListHelper

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
                              picture: product.main_picture.url,
                              product_id: product.id,
                              list_product_id: list_product.id
                          })

          else

            list_product.destroy!

          end

        end

      end

      products = products.sort_by { |item| item[:name] }



      lists.push({
                     list_id: list.id,
                     name: list.name,
                     privacy: list.privacy,
                     is_default: list.is_default,
                     privacy_numeric: list.privacy_before_type_cast,
                     products: products
                 })






    end

    lists

  end

end