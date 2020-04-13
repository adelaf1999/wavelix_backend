class SearchController < ApplicationController

  before_action :authenticate_user!

  def search_users

    # search for users by full_name and username

    search = params[:search]

    @results = []

    if search != nil

      search = search.strip

      if search.length > 0

        users_by_username = User.all.where(user_type: 0).where("username ILIKE ?", "%#{search}%").limit(50)

        user_ids = []

        users_by_username.each do |user|

          if user.id != current_user.id

            user_ids.push(user.id)

          end

        end

        customer_users_by_full_name = CustomerUser.all.where("full_name ILIKE ?", "%#{search}%").where.not(customer_id: user_ids).limit(50)


        customer_users_by_full_name.each do |customer_user|

          if customer_user.customer_id != current_user.id

            user_ids.push(customer_user.customer_id)

          end

        end


        user_ids.uniq!


        combined_users_search = User.where(id: user_ids)


        combined_users_search.each do |user|

          profile = user.profile

          @results.push({ profile_picture: profile.profile_picture.url, username: user.username })

        end


      end

    end



  end


end
