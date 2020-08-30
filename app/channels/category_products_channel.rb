class CategoryProductsChannel < ApplicationCable::Channel

  def subscribed


    if  ( current_user.blank? && current_employee.blank? ) || ( category.blank? )

      reject

    else

      if !current_user.blank?


        if current_user.store_user?

          store_user = StoreUser.find_by(id: current_user.id)

          stream_from "category_#{category.id}_products_store_user_#{store_user.id}"

        else

          reject

        end


      elsif !current_employee.blank?


        if current_employee.has_roles?(:product_manager)

          store_user = current_employee.store_user

          stream_from "category_#{category.id}_products_store_user_#{store_user.id}"

        else

          reject

        end

      end


    end



  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end