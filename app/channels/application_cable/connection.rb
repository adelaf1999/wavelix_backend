module ApplicationCable
  class Connection < ActionCable::Connection::Base

    identified_by :current_user
    identified_by :category
    identified_by :profile

    def connect
      self.current_user = find_user
      self.category = find_category
      self.profile = find_profile
    end

    private


    def find_profile

      profile = Profile.find_by(id: cookies.encrypted[:profile_id])

      if profile != nil
        profile
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
