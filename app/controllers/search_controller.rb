class SearchController < ApplicationController

  include MoneyHelper

  before_action :authenticate_user!

  def index

    @currencies = get_currencies

    if current_user.customer_user?

      customer_user = CustomerUser.find_by(customer_id: current_user.id)

      if customer_user.phone_number_verified?

        @currency = customer_user.default_currency

        current_location = params[:current_location]

        if current_location != nil

          current_location = eval(current_location)

          if current_location.instance_of?(Hash)

            latitude = current_location[:latitude]

            longitude = current_location[:longitude]

            if latitude != nil && longitude != nil

              if is_number?(latitude) && is_number?(longitude)

                latitude = latitude.to_d

                longitude = longitude.to_d

                geo_location = Geocoder.search([latitude, longitude])

                if geo_location.size > 0

                  geo_location_country_code = geo_location.first.country_code

                  customer_user.update!(country: geo_location_country_code)

                  @country = geo_location_country_code


                else

                  @country = customer_user.country

                end

              end

            end

          end

        end


      end


    else

      store_user = StoreUser.find_by(store_id: current_user.id)

      @country = store_user.store_country

      @currency = store_user.currency

    end

  end

  def search_users

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

    # search for users by full_name and username

    # can only search for users whose phone number is also verified as well

    search = params[:search]

    @results = []

    if search != nil

      search = search.strip

      if search.length > 0

        users_by_username = User.all.where(user_type: 0).where("username ILIKE ?", "%#{search}%").limit(50)

        user_ids = []

        users_by_username.each do |user|

          customer_user = CustomerUser.find_by(customer_id: user.id)

          if customer_user.phone_number_verified? && user.id != current_user.id

            user_ids.push(user.id)

          end


        end

        customer_users_by_full_name = CustomerUser.all.where("full_name ILIKE ?", "%#{search}%").where(phone_number_verified: true).where.not(customer_id: user_ids).limit(50)


        customer_users_by_full_name.each do |customer_user|

          if customer_user.customer_id != current_user.id

            user_ids.push(customer_user.customer_id)

          end

        end


        user_ids.uniq!


        combined_users_search = User.where(id: user_ids)


        combined_users_search.each do |user|

          profile = user.profile

          @results.push({ profile_picture: profile.profile_picture.url, username: user.username, profile_id: profile.id })

        end


      end

    end



  end


  def search_stores

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

    # Only verified stores appear in searches

    store_name = params[:store_name]

    country_code = params[:country_code]

    street_name = params[:street_name]

    limit = params[:limit]


    @results = []

    if store_name != nil && country_code != nil && limit != nil

      store_name = store_name.strip

      country = ISO3166::Country.new(country_code)

      is_limit_valid = is_limit_valid?(limit)


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
                            street_name: store.street_name,
                            profile_id: profile.id
                        })
        end

        @results = @results.sort_by { |hsh| hsh[:distance] } # returns sorted array of hashes asc by distance




      end

    end

  end

  def search_products

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

    # Products must be from verified stores and they must be available products

    # Store users can see their own products in search

    product_name = params[:product_name]

    country_code = params[:country_code]

    base_currency = params[:base_currency]

    limit = params[:limit]

    @results = []

    if product_name != nil  && country_code != nil && base_currency != nil && limit != nil


      country = ISO3166::Country.new(country_code)

      is_limit_valid = is_limit_valid?(limit)


      if product_name.length > 0 && country != nil && is_currency_valid?(base_currency) && is_limit_valid

        limit = limit.to_i


        if current_user.store_user?

          current_store_address = StoreUser.find_by(store_id: current_user.id).store_address

          all_products = Product.all.where("name ILIKE ?", "%#{product_name}%").where(product_available: true, store_country: country_code).limit(limit)

          all_products.each do |product|

            store_user = StoreUser.find_by(id: product.category.store_user_id)

            if store_user.verified?

              distance = calculate_distance(current_store_address, store_user.store_address)

              @results = add_product(product, store_user, base_currency, distance, @results)

            end

          end


          sort_by_price = params[:sort_by_price]

          sort_by_distance = params[:sort_by_distance]

          @results = sort_products(sort_by_price, sort_by_distance, @results)


        else


          customer_user = CustomerUser.find_by(customer_id: current_user.id)

          current_customer_address = customer_user.home_address

          all_products = Product.all.where("name ILIKE ?", "%#{product_name}%").where(product_available: true, store_country: country_code).limit(limit)

          all_products.each do |product|

            store_user = StoreUser.find_by(id: product.category.store_user_id)

            if store_user.verified?

              distance = calculate_distance(current_customer_address, store_user.store_address)

              @results = add_product(product, store_user, base_currency, distance, @results)


            end

          end


          sort_by_price = params[:sort_by_price]

          sort_by_distance = params[:sort_by_distance]

          @results = sort_products(sort_by_price, sort_by_distance, @results)



        end


      end




    end




  end


  private

  def is_number?(arg)

    arg.is_a?(Numeric)

  end

  def add_product(product, store_user, base_currency, distance, results)


    if product.currency == base_currency

      price = product.price

    else

      exchange_rates = get_exchange_rates(base_currency)

      price = product.price / exchange_rates[product.currency]

    end

    results.push(
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

    results



  end

  def sort_products(sort_by_price, sort_by_distance, results)

    if sort_by_price != nil && sort_by_price.length > 0 && sort_by_distance == nil

      sort_by_price = sort_by_price.downcase.strip

      if sort_by_price == 'asc'

        results = results.sort_by { |hsh| hsh[:price] }

      elsif sort_by_price == 'desc'


        results = results.sort_by { |hsh| hsh[:price] }.reverse!

      end


    elsif sort_by_distance != nil && sort_by_distance.length > 0 && sort_by_price == nil


      sort_by_distance = sort_by_distance.downcase.strip

      if sort_by_distance == 'asc'

        results = results.sort_by { |hsh| hsh[:distance] }

      elsif sort_by_distance == 'desc'

        results = results.sort_by { |hsh| hsh[:distance] }.reverse!


      end


    end

    results



  end



  def is_limit_valid?(arg)

    res = /^(?<num>\d+)$/.match(arg)

    if res == nil || res == 0
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
