class CategoryProductsChannel < ApplicationCable::Channel

  def start_stream(current_user, current_employee)

    category_id = params[:category_id]

    if !category_id.blank?

      if !current_user.blank?


        if current_user.store_user?

          store_user = StoreUser.find_by(store_id: current_user.id)

          category = store_user.categories.find_by(id: category_id)

          if category != nil

            stream_from "category_#{category.id}_products_store_user_#{store_user.id}"

          else

            reject

          end



        else

          reject

        end


      elsif !current_employee.blank?


        if current_employee.has_roles?(:product_manager)

          store_user = current_employee.store_user

          category = store_user.categories.find_by(id: category_id)

          if category != nil

            stream_from "category_#{category.id}_products_store_user_#{store_user.id}"

          else

            reject

          end



        else

          reject

        end

      end

    else

      reject

    end

  end

  def subscribed

    if  current_user.blank? && current_employee.blank?

      access_token = params[:access_token]

      client = params[:client]

      uid = params[:uid]

      is_user = params[:is_user]

      if !access_token.blank? && !client.blank? && !uid.blank? && !is_user.blank?

        if is_user

          user = User.find_by_uid(uid)

          if user != nil && user.valid_token?(access_token, client)

            start_stream(user, current_employee)

          else

            reject

          end

        else

          employee = Employee.find_by_uid(uid)

          if employee != nil && employee.valid_token?(access_token, client)

            start_stream(current_user, employee)

          else

            reject

          end

        end

      else

        reject

      end



    else

      start_stream(current_user, current_employee)

    end



  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end