module ProductsHelper

  include NotificationsHelper

  def notify_unavailable_products(order)

    store_user = order.store_user

    order.get_ordered_products.each do |ordered_product|

      product = Product.find_by(id: ordered_product.product_id)

      if product != nil && product.stock_quantity == 0 && product.product_available

        message_body = "#{product.name} is out of stock"

        message_data = { product_id: product.id, category_id: product.category_id, edit_product: true }

        send_push_notification(store_user.push_token, message_body, nil, message_data)

        store_user.employees.each do |employee|

          if employee.has_roles?(:product_manager) && employee.active?

            send_push_notification(employee.push_token, message_body, nil, message_data )

          end

        end


      end

    end


  end


end