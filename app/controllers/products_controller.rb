require 'csv'
class ProductsController < ApplicationController

    before_action :deny_to_visitors

    include MoneyHelper

    include ListHelper

    def search_all_products


        if user_signed_in?

            if current_user.store_user?

                store_user = StoreUser.find_by(store_id: current_user.id)

            else

                head :unauthorized

                return

            end

        else


            employee = Employee.find_by(id: current_employee.id)

            if employee.has_roles?(:product_manager) && employee.active?

                store_user = employee.store_user

            else

                head :unauthorized

                return

            end


        end


        @results = []



        products = store_user.products

        name = params[:name]

        if name != nil

            name = name.strip

            products = products.where("name ILIKE ?", "%#{name}%")

        end


        product_available = params[:product_available]

        if product_available != nil

            product_available = eval(product_available)

            if is_boolean?(product_available)

                products = products.where(product_available: product_available)

            end

        end

        stock_quantity = params[:stock_quantity]

        comparison_operator = params[:comparison_operator]

        if stock_quantity != nil && comparison_operator != nil


            if is_whole_number?(stock_quantity) && ['>', '<', '='].include?(comparison_operator)

                stock_quantity = stock_quantity.to_i

                products = products.where("stock_quantity #{comparison_operator} ?", stock_quantity)

            end

        end

        products = products.order(name: :asc)


        products.each do |product|

            @results.push({
                              name: product.name,
                              price: product.price,
                              currency: product.currency,
                              picture: product.main_picture.url,
                              product_available: product.product_available,
                              stock_quantity: product.stock_quantity,
                              category_id: product.category_id,
                              id: product.id
                          })

        end







    end


    def show

        if current_user.customer_user?

            customer_user  = CustomerUser.find_by(customer_id: current_user.id)

            if !customer_user.phone_number_verified?

                @success = false

                return

            end

        end

        product = Product.find_by(id: params[:product_id])

        if product != nil

            # A product can be viewed by the store that owns this product or any other store

            # The product will be shown even if its stock quantity is 0 and will be marked as out of stock

            # The product wont be shown only if its not available

            # Can only view products of verified stores

            if product.product_available

                store_user = product.category.store_user

                store = store_user.store

                store_profile = store.profile

                if store_user.verified?

                    @success = true


                    @product_pictures = []

                    @product_pictures.push(product.main_picture)

                    @product_pictures += product.product_pictures

                    @product = product.to_json

                    @product_options = {}

                    @product_details = {}

                    product.product_attributes.each do |key, value|

                        if value.instance_of?(Array)

                            value.prepend('Select option')

                            @product_options[key] = value

                        else

                            @product_details[key] = value

                        end

                    end

                    @store = {}
                    @store[:name] = store_user.store_name
                    @store[:logo] = store_profile.profile_picture.url
                    @store[:profile_id] = store_profile.id
                    @store[:username] = store.username
                    @store[:location] = store_user.store_address

                    @has_sensitive_products = store_user.has_sensitive_products
                    @handles_delivery = store_user.handles_delivery
                    @maximum_delivery_distance = store_user.maximum_delivery_distance


                    if current_user.customer_user?

                        customer_user = CustomerUser.find_by(customer_id: current_user.id)

                        @customer_country = customer_user.country

                        @home_address = customer_user.home_address

                        # Show the product price in the default selected currency of the customer

                        @product_currency = customer_user.default_currency


                        if product.currency == @product_currency

                            @product_price = product.price

                        else

                            exchange_rates = get_exchange_rates(@product_currency)

                            @product_price = product.price / exchange_rates[product.currency]

                        end

                        @has_saved_card = customer_user.payment_source_setup?


                        @similar_items = Product.similar_items(product, customer_user)

                        @has_added_list_product = customer_user.added_list_product?(product.id)

                        @lists = customer_user_lists(customer_user)


                    else


                        current_store_user = StoreUser.find_by(store_id: current_user.id)

                        @product_currency = current_store_user.currency

                        if product.currency == @product_currency

                            @product_price = product.price

                        else

                            exchange_rates = get_exchange_rates(@product_currency)

                            @product_price = product.price / exchange_rates[product.currency]

                        end



                    end



                else

                    @success = false

                end




            else

                @success = false

            end



        else

            @success = false

        end


    end

    def create


        if user_signed_in?

            if current_user.store_user?

                store_user = StoreUser.find_by(store_id: current_user.id)

            else

                head :unauthorized

                return

            end

        else


            employee = Employee.find_by(id: current_employee.id)

            if employee.has_roles?(:product_manager) && employee.active?

                store_user = employee.store_user

            else

                head :unauthorized

                return

            end


        end


        missing_params = false

        req_params = [:name,  :price, :main_picture, :category_id]

        # optional params: description, stock_quantity


        product_params = params.permit(
            :name,
            :description,
            :price,
            :main_picture,
            :category_id,
            :stock_quantity,
            :product_attributes,
            {product_pictures: []},
            :isBase64
        )

        req_params.each do |p|

            if product_params[p] == nil
                missing_params = true
                break
            end

        end




        if !missing_params

            name = product_params[:name]

            description = product_params[:description]

            price = product_params[:price]

            main_picture = product_params[:main_picture]

            category_id = product_params[:category_id]

            stock_quantity = product_params[:stock_quantity]

            product_attributes = product_params[:product_attributes]

            product_pictures = product_params[:product_pictures]

            isBase64 = product_params[:isBase64]

            category = store_user.categories.find_by(id: category_id)

            if isBase64 != nil

                isBase64 = eval(isBase64)

            end

            if category != nil


                product = Product.new

                product.category_id = category_id

                if name.length == 0

                    @success = false
                    @message = "Name cannot be empty"
                    return

                else

                    product.name = name

                end

                if description != nil && description.length > 0

                    product.description = description

                end



                if is_valid_price?(price.to_s, store_user)

                    product.price = price.to_d


                else

                    @success = false
                    @message = "Invalid price"
                    return

                end



                if isBase64 != nil && isBase64


                    if  main_picture != nil

                        main_picture = eval(main_picture)

                        if main_picture.instance_of?(Hash) && main_picture.size > 0


                            pic_name = main_picture[:name]
                            pic_type = main_picture[:type]
                            pic_uri = main_picture[:uri]

                            if pic_name != nil && pic_type != nil && pic_uri != nil

                                pic_base64_uri_array = pic_uri.split(",")

                                pic_base64_uri = pic_base64_uri_array[pic_base64_uri_array.length - 1]

                                temp_pic = Tempfile.new(pic_name)
                                temp_pic.binmode
                                temp_pic.write Base64.decode64(pic_base64_uri)
                                temp_pic.rewind

                                pic_name_array = pic_name.split(".")
                                extension = pic_name_array[pic_name_array.length - 1]
                                valid_extensions = ["png" , "jpeg", "jpg", "gif"]

                                if valid_extensions.include?(extension)

                                    main_picture = ActionDispatch::Http::UploadedFile.new({
                                                                                              tempfile: temp_pic,
                                                                                              type: pic_type,
                                                                                              filename: pic_name
                                                                                          })

                                    product.main_picture = main_picture

                                end

                            else

                                @success = false
                                @message = "Invalid main picture"
                                return


                            end

                        else

                            @success = false
                            @message = "Invalid main picture"
                            return

                        end


                    else

                        @success = false
                        @message = "Upload a main picture for your product."
                        return

                    end



                else



                    if  !main_picture.is_a?(ActionDispatch::Http::UploadedFile) || !is_picture_valid?(main_picture)

                        @success = false
                        @message = "Make sure you uploaded an appropriate picture with valid extension."

                        return

                    else


                        product.main_picture = main_picture

                    end


                end



                if stock_quantity != nil && !stock_quantity.empty?

                    if !is_positive_integer?(stock_quantity.to_s)

                        @success = false
                        @message = "Stock quantity must be a positive integer"
                        return

                    else


                        product.stock_quantity = stock_quantity.to_i

                    end



                end


                if category.subcategories.length > 0


                    @success = false
                    @message = "Cannot add product since category already has subcategories."
                    return

                end



                # validate product_attributes as necessary

                if product_attributes != nil

                    begin

                        product_attributes = eval(product_attributes)

                        if product_attributes.instance_of?(Hash) && product_attributes.length > 0

                            product.product_attributes = product_attributes

                        else

                            @success = false
                            @message = "Invalid product attributes"
                            return

                        end

                    rescue  SyntaxError, NameError

                        @success = false
                        @message = "Invalid product attributes"
                        return

                    end


                end

                # validate product pictures as necessary

                if product_pictures != nil

                    if isBase64 != nil && isBase64


                        product_pictures = decode_base64_pictures(product_pictures)

                        product.product_pictures = product_pictures

                    else


                        if !are_product_pictures_valid?(product_pictures)

                            @success = false
                            @message = "Make sure you uploaded an appropriate pictures with valid extension."
                            return

                        else

                            product.product_pictures = product_pictures

                        end


                    end


                end




                if product.save

                    @success = true
                    @message = "Succesfully created product"

                else

                    @success = false
                    @message = "Error creating product"

                end


            else

                @success = false
                @message = "Category may have been moved or deleted"

            end


        else

            @success = false
            @message = "Missing required parameters"

        end



    end

    def get_products


        if user_signed_in?

            if current_user.store_user?

                store_user = StoreUser.find_by(store_id: current_user.id)

            else

                head :unauthorized

                return

            end

        else


            employee = Employee.find_by(id: current_employee.id)

            if employee.has_roles?(:product_manager) && employee.active?

                store_user = employee.store_user

            else

                head :unauthorized

                return

            end


        end



        category = store_user.categories.find_by(id: params[:category_id])

        if category != nil

            if category.subcategories.length > 0

                # category has subcategories

                @success = false

            else



                products = []

                category.products.order('name ASC').each do |product|
                    products.push(product.to_json)
                end

                @success = true

                @products = products

                @category_name = category.name


            end



        else

            # user does not own the category

            # or category deleted

            @success = false

        end



    end

    def search_product



        if user_signed_in?

            if current_user.store_user?

                store_user = StoreUser.find_by(store_id: current_user.id)

            else

                head :unauthorized

                return

            end

        else


            employee = Employee.find_by(id: current_employee.id)

            if employee.has_roles?(:product_manager) && employee.active?

                store_user = employee.store_user

            else

                head :unauthorized

                return

            end


        end


        name = params[:name]

        category_id = params[:category_id]

        if name != nil && category_id != nil

            @products = []

            category = store_user.categories.find_by(id: category_id)

            if category != nil

                category_products = category.products

                category_products = category_products.where("name ILIKE ?", "%#{name}%").order('name ASC')

                category_products.each do |category_product|

                    @products.push(category_product.to_json)

                end

            end


        end


    end

    def remove_product_image


        if user_signed_in?

            if current_user.store_user?

                store_user = StoreUser.find_by(store_id: current_user.id)

            else

                head :unauthorized

                return

            end

        else


            employee = Employee.find_by(id: current_employee.id)

            if employee.has_roles?(:product_manager) && employee.active?

                store_user = employee.store_user

            else

                head :unauthorized

                return

            end


        end



        category = store_user.categories.find_by(id: params[:category_id])

        if category != nil

            product = category.products.find_by(id: params[:product_id])

            if product != nil

                image_name = params[:image_name]

                if image_name != nil && image_name.length > 0

                    product.remove_image(image_name)

                    @product_pictures = product.get_images.to_json


                end



            end


        end



    end

    def store_owns_product_check



        if user_signed_in?

            if current_user.store_user?

                store_user = StoreUser.find_by(store_id: current_user.id)

            else

                head :unauthorized

                return

            end

        else


            employee = Employee.find_by(id: current_employee.id)

            if employee.has_roles?(:product_manager) && employee.active?

                store_user = employee.store_user

            else

                head :unauthorized

                return

            end


        end


        category_id = params[:category_id]

        category = store_user.categories.find_by(id: category_id)

        if category != nil

            product = category.products.find_by(id: params[:product_id])

            if product != nil

                @success = true
                @product = product.to_json
                @product_pictures = product.get_images.to_json
                @minimum_product_price = store_user.get_minimum_product_price

            else

                @success = false

            end

        else

            @success = false

        end



    end

    def update_product



        if user_signed_in?

            if current_user.store_user?

                store_user = StoreUser.find_by(store_id: current_user.id)

            else

                head :unauthorized

                return

            end

        else


            employee = Employee.find_by(id: current_employee.id)

            if employee.has_roles?(:product_manager) && employee.active?

                store_user = employee.store_user

            else

                head :unauthorized

                return

            end


        end


        category_id = params[:category_id]

        product_id = params[:product_id]

        if category_id != nil && product_id != nil


            category = store_user.categories.find_by(id: category_id)

            if category != nil

                product = category.products.find_by(id: product_id)

                if product != nil


                    # user owns the product can start updating

                    # PRODUCT NAME VALIDATORS



                    name = params[:name]
                    description = params[:description]
                    price = params[:price]
                    stock_quantity = params[:stock_quantity]
                    product_available = eval(params[:product_available])
                    product_attributes = params[:product_attributes]
                    main_picture = params[:main_picture]
                    product_pictures = params[:product_pictures]
                    isBase64 = params[:isBase64]


                    if isBase64 != nil

                        isBase64 = eval(isBase64.downcase)

                    end

                    if name != nil

                        if name.length == 0


                            @success = false
                            @message = "Product name cannot be empty"
                            return

                        else

                            product.name = name

                        end

                    end




                    if isBase64 != nil && isBase64


                        if main_picture != nil

                            main_picture = eval(main_picture)

                            if main_picture.instance_of?(Hash) && main_picture.size > 0


                                pic_name = main_picture[:name]
                                pic_type = main_picture[:type]
                                pic_uri = main_picture[:uri]

                                if pic_name != nil && pic_type != nil && pic_uri != nil

                                    pic_base64_uri_array = pic_uri.split(",")

                                    pic_base64_uri = pic_base64_uri_array[pic_base64_uri_array.length - 1]

                                    temp_pic = Tempfile.new(pic_name)
                                    temp_pic.binmode
                                    temp_pic.write Base64.decode64(pic_base64_uri)
                                    temp_pic.rewind

                                    pic_name_array = pic_name.split(".")
                                    extension = pic_name_array[pic_name_array.length - 1]
                                    valid_extensions = ["png" , "jpeg", "jpg", "gif"]

                                    if valid_extensions.include?(extension)

                                        main_picture = ActionDispatch::Http::UploadedFile.new({
                                                                                                  tempfile: temp_pic,
                                                                                                  type: pic_type,
                                                                                                  filename: pic_name
                                                                                              })

                                        product.main_picture = main_picture

                                    end

                                else


                                    @success = false
                                    @message = "Invalid main picture"
                                    return


                                end

                            else


                                @success = false
                                @message = "Invalid main picture"
                                return

                            end


                        end



                    else


                        if main_picture != nil

                            if !main_picture.is_a?(ActionDispatch::Http::UploadedFile) || !is_picture_valid?(main_picture)

                                @success = false
                                @message = "Make sure you uploaded an appropriate picture with valid extension for the main picture."
                                return

                            else

                                product.main_picture = main_picture

                            end


                        end





                    end




                    if price != nil

                        if !is_valid_price?(price.to_s, store_user)


                            @success = false
                            @message = "Invalid price"
                            return

                        else

                            product.price = price.to_d

                        end

                    end



                    if stock_quantity == nil || stock_quantity.empty?

                        product.stock_quantity = nil

                        if product_available != nil && is_boolean?(product_available)

                            product.product_available = product_available

                        end

                    else

                        if is_whole_number?(stock_quantity)

                            stock_quantity = stock_quantity.to_i

                            product.stock_quantity = stock_quantity

                            if stock_quantity == 0


                                if product_available != nil && is_boolean?(product_available)

                                    if product_available

                                        @success = false
                                        @message = "Cannot set the product availability on unless the stock quantity is greater zero"
                                        return

                                    else

                                        product.product_available = product_available

                                    end



                                end

                            else


                                if product_available != nil && is_boolean?(product_available)

                                    product.product_available = product_available

                                end


                            end

                        end


                    end

                    if description != nil

                        product.description = description

                    end

                    if product_attributes != nil

                        begin

                            product_attributes = eval(product_attributes)



                            if product_attributes.instance_of?(Hash)

                                # can be empty hash

                                product.product_attributes = product_attributes


                            else

                                @success = false
                                @message = "Invalid product attributes"
                                return

                            end



                        rescue  SyntaxError, NameError

                            @success = false
                            @message = "Invalid product attributes"
                            return


                        end


                    end




                    if product_pictures != nil

                        if isBase64 != nil && isBase64

                            product_pictures = decode_base64_pictures(product_pictures)

                            if product.product_pictures.size > 0
                                # there exists pictures
                                product.product_pictures += product_pictures
                            else
                                product.product_pictures = product_pictures
                            end



                        else


                            if !are_product_pictures_valid?(product_pictures)


                                @success = false
                                @message = "Make sure you uploaded an appropriate pictures with valid extension."
                                return

                            else

                                if product.product_pictures.size > 0
                                    # there exists pictures
                                    product.product_pictures += product_pictures
                                else
                                    product.product_pictures = product_pictures
                                end


                            end


                        end


                    end



                    if product.save!

                        @success = true
                        @message = "Updated product"
                        @product = product.to_json
                        @product_pictures = product.get_images.to_json

                        return

                    else

                        @success = false
                        @message = "Error updating"
                        return

                    end



                end


            end



        end




    end


    def import_products


        if user_signed_in?

            if current_user.store_user?

                store_user = StoreUser.find_by(store_id: current_user.id)

            else

                head :unauthorized

                return

            end

        else


            employee = Employee.find_by(id: current_employee.id)

            if employee.has_roles?(:product_manager) && employee.active?

                store_user = employee.store_user

            else

                head :unauthorized

                return

            end


        end

        category = store_user.categories.find_by(id: params[:category_id])

        if category != nil

            pictures = params[:product_pictures]

            file = params[:file]

            isBase64 = params[:isBase64]

            if category.subcategories.length > 0

                @success = false
                @message = "Cannot import products since category already has subcategories."
                return

            end


            if file == nil || !file.is_a?(ActionDispatch::Http::UploadedFile) || !is_csv_file_valid?(file)

                @success = false
                @message = "The file to import products must be of type csv."
                return

            end

            if  pictures == nil || !pictures.instance_of?(Array)

                @success = false
                @message = "Upload pictures to continue"
                return

            end


            if isBase64 != nil

                isBase64 = eval(isBase64)

                if isBase64
                    pictures = decode_base64_pictures(pictures)
                end

            end


            csv_file = file.tempfile.open

            filepath = csv_file.path

            csv = CSV.read(filepath, headers: true, converters: :numeric)

            csv_header_map = get_csv_file_header_map(csv)

            # Make sure all headers are present

            if csv_header_map[:name].empty? || csv_header_map[:price].empty? || csv_header_map[:main_picture].empty?

                @success = false

                @message = "Make sure your csv file has all of the following headers: name, price, and main picture"

                csv_file.close

                return

            end

            # Even if the user might have uploaded extra pictures, or if there are some missing pictures,
            #  or if there are some pictures of invalid type
            #  proceed and try to make as much as valid products as possible
            #  then you can report to the user how many products were imported
            #  and the names of those that failed to import so he can re import them

            csv.each do |row|

                can_save = true

                name = row[ csv_header_map[:name] ]
                description = row[ csv_header_map[:description] ]
                price = row[ csv_header_map[:price] ]
                main_picture = get_uploaded_picture(pictures, row[ csv_header_map[:main_picture] ] )
                stock_quantity = row[ csv_header_map[:stock_quantity] ]

                if name == nil || name.length == 0
                    can_save = false
                end

                if can_save &&  description == nil
                    description = ''
                end

                if can_save &&   ( price == nil || !is_valid_price?(price.to_s, store_user) )
                    can_save = false
                else
                    price = price.to_d
                end


                if isBase64 != nil &&  isBase64

                    if can_save && main_picture == nil
                        can_save = false
                    end

                else

                    if can_save &&  (  main_picture == nil || !main_picture.is_a?(ActionDispatch::Http::UploadedFile) || !is_picture_valid?(main_picture))
                        can_save = false
                    end

                end


                if can_save &&  stock_quantity != nil

                    if stock_quantity == ''

                        stock_quantity = nil

                    else

                        if !is_positive_integer?(stock_quantity.to_s)

                            can_save = false

                        else

                            stock_quantity = stock_quantity.to_i

                        end

                    end

                end


                if can_save

                    # All other columns add them to the product attributes

                    # Make sure that the other headers are not the special headers

                    # Or that they resemble the special headers in some way

                    product_attributes = {}
                    product_pictures = []
                    special_headers = csv_header_map.values


                    csv.headers.each do |header|

                        if header != nil

                            if is_csv_pictures_header?(header)

                                row_value = row[header]

                                if row_value != nil && !row_value.to_s.empty?

                                    if row_value.is_a?(String) && row_value.include?(",")

                                        row_value = row_value.strip

                                        picture_names = row_value.split(",")

                                        picture_names.each do |picture_name|

                                            picture_name = picture_name.strip

                                            picture = get_uploaded_picture(pictures, picture_name)

                                            if isBase64 != nil &&  isBase64

                                                if picture != nil

                                                    product_pictures.push(picture)

                                                end

                                            else

                                                if picture != nil  && picture.is_a?(ActionDispatch::Http::UploadedFile) && is_picture_valid?(picture)

                                                    product_pictures.push(picture)

                                                end

                                            end


                                        end

                                    end

                                end

                            else

                                if !special_headers.include?(header) &&
                                    !header.include?("name") &&
                                    !description_contains(header) &&
                                    !price_contains(header) &&
                                    !main_picture_contains(header) &&
                                    !stock_quantity_contains(header)

                                    row_value = row[ header ]

                                    if row_value != nil


                                        if !product_attributes.has_key?(header) &&  !row_value.to_s.empty?

                                            # makes sure product keys are unique

                                            if row_value.is_a?(String)

                                                row_value = row_value.strip

                                                if row_value.include?(",")

                                                    is_row_list = true

                                                    row_value_array = row_value.split(",")

                                                    row_value_array.each do |value|

                                                        value = value.strip

                                                        if value.include?(" ")

                                                            value_array = value.split(" ")

                                                            if value_array.size > 2

                                                                is_row_list = false

                                                                break

                                                            end

                                                        end


                                                    end

                                                    if is_row_list

                                                        header = header.downcase

                                                        product_attributes[header] = row_value_array

                                                    end



                                                elsif row_value.include?("-") && !product_attributes.has_key?(header)

                                                    is_row_list = true

                                                    row_value_array = row_value.split("-")

                                                    row_value_array.each do |value|

                                                        value = value.strip

                                                        if value.include?(" ")

                                                            value_array = value.split(" ")

                                                            if value_array.size > 2

                                                                is_row_list = false

                                                                break

                                                            end

                                                        end


                                                    end

                                                    if is_row_list

                                                        header = header.downcase

                                                        product_attributes[header] = row_value_array

                                                    end

                                                end


                                                if !product_attributes.has_key?(header)

                                                    header = header.downcase

                                                    product_attributes[header] = row_value


                                                end


                                            else

                                                header = header.downcase

                                                product_attributes[header] = row_value

                                            end

                                        end



                                    end



                                end

                            end



                        end



                    end

                    product = Product.new
                    product.name = name
                    product.description = description
                    product.price = price
                    product.main_picture = main_picture
                    product.category_id = category.id
                    product.stock_quantity = stock_quantity

                    if product_attributes.size > 0
                        product.product_attributes = product_attributes
                    end

                    if product_pictures.size > 0

                        product.product_pictures = product_pictures

                    end


                    if product.save!

                        new_products = []

                        category.products.order('name ASC').each do |p|
                            new_products.push(p)
                        end

                        new_products = new_products.to_json

                        ActionCable.server.broadcast "category_#{category.id}_products_store_user_#{store_user.id}", {products: new_products}

                    end


                end





            end

            @success = true


            csv_file.close


        end


    end

    private

    def is_boolean?(arg)
        [true, false].include?(arg)
    end

    def decode_base64_pictures(pictures)

        decoded_pictures = []

        pictures.each do |pic|

            pic = eval(pic)

            if pic != nil && pic.instance_of?(Hash) && pic.size > 0

                pic_name = pic[:name]
                pic_type = pic[:type]
                pic_uri = pic[:uri]

                if pic_name != nil && pic_type != nil && pic_uri != nil

                    pic_base64_uri_array = pic_uri.split(",")

                    pic_base64_uri = pic_base64_uri_array[pic_base64_uri_array.length - 1]

                    temp_pic = Tempfile.new(pic_name)
                    temp_pic.binmode
                    temp_pic.write Base64.decode64(pic_base64_uri)
                    temp_pic.rewind

                    pic_name_array = pic_name.split(".")
                    extension = pic_name_array[pic_name_array.length - 1]
                    valid_extensions = ["png" , "jpeg", "jpg", "gif"]

                    if valid_extensions.include?(extension)

                        pic_file = ActionDispatch::Http::UploadedFile.new({
                                                                              tempfile: temp_pic,
                                                                              type: pic_type,
                                                                              filename: pic_name
                                                                          })

                        decoded_pictures.push(pic_file)


                    end

                end

            end

        end

        decoded_pictures

    end

    def get_uploaded_picture(pictures, picture_name)

        found_picture = false

        pictures.each do |picture|

            if picture.original_filename == picture_name
                found_picture = true
                return picture
            end

        end

        if !found_picture
            nil
        end




    end

    def get_csv_file_header_map(csv)

        header_map = {
            name: '',
            description: '',
            price: '',
            main_picture: '',
            stock_quantity: ''
        }

        csv.headers.each do |header|

            original_header = header

            if header != nil

                header = header.downcase

                header = header.strip

                if header == 'name' && header_map[:name].empty?
                    header_map[:name] = original_header
                end

                if description_contains(header) && header_map[:description].empty?
                    header_map[:description] = original_header
                end

                if price_contains(header) && header_map[:price].empty?
                    header_map[:price] = original_header
                end


                if main_picture_contains(header) && header_map[:main_picture].empty?

                    header_map[:main_picture] = original_header

                end

                if stock_quantity_contains(header) && header_map[:stock_quantity].empty?

                    header_map[:stock_quantity] = original_header

                end

            end




        end

        header_map


    end

    def is_csv_pictures_header?(header)

        header == 'pictures' || header == 'images' || header == 'photos' || header == 'pics' || header == 'imgs'

    end

    def description_contains(header)

        header == 'description' || header == 'information' || header == 'info' || header == 'about' || header == 'details'

    end

    def price_contains(header)

        header == 'price' || header == 'cost'

    end

    def main_picture_contains(header)

        header == 'main picture' || header == 'picture' || header == 'image' || header == 'photo' || header == 'thumbnail'

    end

    def stock_quantity_contains(header)

        header == 'stock quantity' || header == 'quantity' || header == 'qty'

    end

    def is_csv_file_valid?(file)

        filename = file.original_filename.split(".")
        extension = filename[filename.length - 1]
        valid_extensions = ["csv"]
        valid_extensions.include?(extension)


    end

    def is_whole_number?(arg)

        # 0, 1, 2, 3

        res = /^(?<num>\d+)$/.match(arg)

        if res == nil
            false
        else
            true
        end

    end

    def is_positive_integer?(arg)

        # 1, 2, 3, 4

        res = /^(?<num>\d+)$/.match(arg)

        if res == nil
            false
        else

            arg = arg.to_i

            arg != 0


        end

    end

    def is_valid_price?(price, store_user)

        # price must be a number greater than or equal to the minimum product price

        if /^\d+([.]\d+)?$/.match(price) == nil

            false

        else

            price = price.to_f.round(2)

            minimum_product_price = store_user.get_minimum_product_price

            price >= minimum_product_price


        end
    end

    def is_picture_valid?(picture)

        filename = picture.original_filename.split(".")
        extension = filename[filename.length - 1]
        valid_extensions = ["png" , "jpeg", "jpg", "gif"]
        valid_extensions.include?(extension)

    end

    def are_product_pictures_valid?(product_pictures)

        valid = true

        # !main_picture.is_a?(ActionDispatch::Http::UploadedFile)

        product_pictures.each do |picture|

            if picture.is_a?(ActionDispatch::Http::UploadedFile)

                filename = picture.original_filename.split(".")
                extension = filename[filename.length - 1]
                valid_extensions = ["png" , "jpeg", "jpg", "gif"]
                if !valid_extensions.include?(extension)
                    valid = false
                    break
                end

            else
                valid = false
                break

            end

        end

        valid

    end

    def deny_to_visitors

        head :unauthorized unless user_signed_in? or employee_signed_in?

    end




end
