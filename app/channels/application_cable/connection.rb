module ApplicationCable
  class Connection < ActionCable::Connection::Base

    identified_by :current_user
    identified_by :category
    identified_by :cart
    identified_by :current_employee

    def connect
      self.current_user = find_user
      self.category = find_category
      self.cart = find_cart
      self.current_employee = find_employee
    end

    private

    def find_employee

      employee = Employee.find_by(id: cookies.encrypted[:employee_id])

      if employee != nil

        employee

      end


    end

    def find_cart

      cart = Cart.find_by(id: cookies.encrypted[:cart_id])

      if cart != nil
        cart
      end

    end


    def find_user

      user = User.find_by(id: cookies.encrypted[:user_id])

      if user != nil
        user
      end

    end

    def find_category


      store_user = StoreUser.find_by(store_id: cookies.encrypted[:user_id])

      if store_user != nil


        category = store_user.categories.find_by(id: cookies.encrypted[:category_id])

        if category != nil

          category

        end


      end


    end



  end
end
