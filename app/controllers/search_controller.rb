class SearchController < ApplicationController

  include MoneyHelper

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

    store_name = params[:store_name]

    country_code = params[:country_code]

    street_name = params[:street_name]

    limit = params[:limit]

    @results = []

    if store_name != nil && country_code != nil && limit != nil

      store_name = store_name.strip

      country = ISO3166::Country.new(country_code)

      is_limit_valid = is_positive_integer?(limit)

      if store_name.length > 0 && country != nil && is_limit_valid


          limit = limit.to_i

          if current_user.store_user?


            if street_name != nil && street_name.length > 0

              stores = StoreUser.all.where("store_name ILIKE ?", "%#{store_name}%" ).where("street_name ILIKE ?", "%#{street_name}%" ).where(status: 1, store_country: country_code).where.not(store_id: current_user.id).limit(limit)

            else

              stores = StoreUser.all.where("store_name ILIKE ?", "%#{store_name}%" ).where(status: 1, store_country: country_code).where.not(store_id: current_user.id).limit(limit)

            end



            store_user = StoreUser.find_by(store_id: current_user.id)

            user_address = store_user.store_address

          else

            if street_name != nil && street_name.length > 0

              stores = StoreUser.all.where("store_name ILIKE ?", "%#{store_name}%" ).where("street_name ILIKE ?", "%#{street_name}%" ).where(status: 1, store_country: country_code).limit(limit)

            else

              stores = StoreUser.all.where("store_name ILIKE ?", "%#{store_name}%" ).where(status: 1, store_country: country_code).limit(limit)

            end



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
                              distance: distance,
                              street_name: store.street_name
                          })
          end

         @results = @results.sort_by { |hsh| hsh[:distance] } # returns sorted array of hashes asc by distance




      end

    end

  end

  def search_products

    # Products must be from verified stores and they must be available products

    # Store users should not see their own products in the search


    product_name = params[:product_name]

    country_code = params[:country_code]

    base_currency = params[:base_currency]

    @results = []

    if product_name != nil  && country_code != nil && base_currency != nil


      country = ISO3166::Country.new(country_code)


      if product_name.length > 0 && country != nil && is_currency_valid?(base_currency)

        if current_user.store_user?

          current_store_address = StoreUser.find_by(store_id: current_user.id).store_address

          all_products = Product.all.where("name ILIKE ?", "%#{product_name}%").where(product_available: true)

          all_products.each do |product|

            store_user = StoreUser.find_by(id: product.category.store_user_id)

            if store_user.verified? && store_user.store_id != current_user.id && store_user.store_country == country_code

              distance = calculate_distance(current_store_address, store_user.store_address)

              if product.currency == base_currency

                price = product.price

              else

                exchange_rates = get_exchange_rate # currency is the base currency, in this case USD

                price = product.price / exchange_rates[product.currency.to_sym]

              end

              @results.push(
                  {
                      name: product.name,
                      store_name: store_user.store_name,
                      picture: product.main_picture.url,
                      distance: distance,
                      product_id: product.id,
                      price: price,
                      currency: base_currency
                  }
              )

            end

          end


          sort_by_price = params[:sort_by_price]

          sort_by_distance = params[:sort_by_distance]

          if sort_by_price != nil && sort_by_price.length > 0 && sort_by_distance == nil

            sort_by_price = sort_by_price.downcase.strip

            if sort_by_price == 'asc'

              @results = @results.sort_by { |hsh| hsh[:price] }

            elsif sort_by_price == 'desc'


              @results = @results.sort_by { |hsh| hsh[:price] }.reverse!

            end


          elsif sort_by_distance != nil && sort_by_distance.length > 0 && sort_by_price == nil


            sort_by_distance = sort_by_distance.downcase.strip

            if sort_by_distance == 'asc'

              @results = @results.sort_by { |hsh| hsh[:distance] }

            elsif sort_by_distance == 'desc'

              @results = @results.sort_by { |hsh| hsh[:distance] }.reverse!


            end


          end


        else


          customer_user = CustomerUser.find_by(customer_id: current_user.id)

          current_customer_address = customer_user.home_address

          all_products = Product.all.where("name ILIKE ?", "%#{product_name}%").where(product_available: true)

          all_products.each do |product|

            store_user = StoreUser.find_by(id: product.category.store_user_id)

            if store_user.verified? && store_user.store_country == country_code

              distance = calculate_distance(current_customer_address, store_user.store_address)

              if product.currency == base_currency

                price = product.price

              else

                exchange_rates = get_exchange_rate # currency is the base currency, in this case USD

                price = product.price / exchange_rates[product.currency.to_sym]

              end

              @results.push(
                  {
                      name: product.name,
                      store_name: store_user.store_name,
                      picture: product.main_picture.url,
                      distance: distance,
                      product_id: product.id,
                      price: price,
                      currency: base_currency
                  }
              )

            end

          end


          sort_by_price = params[:sort_by_price]
          sort_by_distance = params[:sort_by_distance]

          if sort_by_price != nil && sort_by_price.length > 0 && sort_by_distance == nil

            sort_by_price = sort_by_price.downcase.strip

            if sort_by_price == 'asc'

              @results = @results.sort_by { |hsh| hsh[:price] }

            elsif sort_by_price == 'desc'


              @results = @results.sort_by { |hsh| hsh[:price] }.reverse!

            end


          elsif sort_by_distance != nil && sort_by_distance.length > 0 && sort_by_price == nil


            sort_by_distance = sort_by_distance.downcase.strip

            if sort_by_distance == 'asc'

              @results = @results.sort_by { |hsh| hsh[:distance] }

            elsif sort_by_distance == 'desc'

              @results = @results.sort_by { |hsh| hsh[:distance] }.reverse!


            end


          end






        end


      end




    end




  end


  private


  def get_exchange_rate

    # Temporary method till we add fixer.io api just for development purposes

    # Assumes base to be USD and returns conversion rates for LBP, EUR and GBP

    # Products can be in currency LBP, EUR, GBP and USD

    {
        base: 'USD',
        LBP: 1506.14,
        EUR: 0.92,
        GBP: 0.80
    }


  end

  def is_positive_integer?(arg)

    res = /^(?<num>\d+)$/.match(arg)

    if res == nil
      false
    else
      true
    end

  end

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
