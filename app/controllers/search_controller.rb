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


  def search_stores

    # Only verified stores appear in searches

    search = params[:search]

    @results = []

    if search != nil

      search = search.strip

      if search.length > 0

          if current_user.store_user?

            stores = StoreUser.all.where("store_name ILIKE ?", "%#{search}%" ).where(status: 1).where.not(store_id: current_user.id)


            store_user = StoreUser.find_by(store_id: current_user.id)

            user_address = store_user.store_address

          else

            stores = StoreUser.all.where("store_name ILIKE ?", "%#{search}%" ).where(status: 1)

            customer_user = CustomerUser.find_by(customer_id: current_user.id)

            user_address = customer_user.home_address

          end


          stores.each do |store|

            user = User.find_by(id: store.store_id)

            profile = user.profile

            distance = calculate_distance(user_address, store.store_address)

            @results.push({
                              profile_picture: profile.profile_picture.url,
                              username: user.username,
                              country: store.store_country,
                              name: store.store_name,
                              distance: distance
                          })
          end

         @results = @results.sort_by { |hsh| hsh[:distance] } # returns sorted array of hashes asc by distance




      end

    end

  end


  private

  def calculate_distance(loc1, loc2)

    # https://stackoverflow.com/questions/12966638/how-to-calculate-the-distance-between-two-gps-coordinates-without-using-google-m


    rad_per_deg = Math::PI/180  # PI / 180
    rkm = 6371                  # Earth radius in kilometers
    rm = rkm * 1000             # Radius in meters

    dlat_rad = (loc2[:latitude]-loc1[:latitude]) * rad_per_deg  # Delta, converted to rad
    dlon_rad = (loc2[:longitude]-loc1[:longitude]) * rad_per_deg


    lat1_rad = loc1[:latitude] * rad_per_deg
    lat2_rad = loc2[:latitude] * rad_per_deg

    a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1-a))

    (rm * c) / 1000.0 # Delta in KM

  end





end
