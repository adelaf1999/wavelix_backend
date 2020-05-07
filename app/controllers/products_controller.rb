require 'csv'
class ProductsController < ApplicationController

    before_action :authenticate_user!

    def create

        if current_user.store_user?

            store_user = StoreUser.find_by(store_id: current_user.id)

            missing_params = false

            req_params = [:name, :description, :price, :main_picture, :category_id, :stock_quantity]


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

                    valid = true

                    if name.length == 0
                        valid = false
                        @success = false
                        @message = "Name cannot be empty"
                        return
                    end

                    if valid && description.length == 0
                        valid = false
                        @success = false
                        @message = "Description cannot be empty"
                        return
                    end


                    if valid

                        if is_valid_price?(price.to_s)

                            price = price.to_d 

                        else

                            valid = false
                            @success = false
                            @message = "Invalid price"

                            return

                        end


                    end


                    if isBase64 != nil && isBase64


                        if valid && main_picture != nil


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
                                    end

                                else

                                    valid = false
                                    @success = false
                                    @message = "Invalid main picture"
                                    return


                                end

                            else

                                valid = false
                                @success = false
                                @message = "Invalid main picture"

                                return

                            end


                        else

                            valid = false
                            @success = false
                            @message = "Upload a main picture for your product."

                            return

                        end



                    else


                        if valid && ( !main_picture.is_a?(ActionDispatch::Http::UploadedFile) || !is_picture_valid?(main_picture) )

                            valid = false
                            @success = false
                            @message = "Make sure you uploaded an appropriate picture with valid extension."

                            return

                        end


                    end




                    if valid &&  ( !is_positive_integer?(stock_quantity.to_s) || stock_quantity.to_i == 0 )

                        valid = false
                        @success = false
                        @message = "Stock quantity must be a positive integer"

                        return

                    end


                    if valid && category.subcategories.length > 0 

                        valid = false
                        @success = false
                        @message = "Cannot add product since category already has subcategories."

                        return

                    end

                    product = Product.new

                    # validate product_attributes as necessary

                    if product_attributes != nil

                        begin

                            product_attributes = eval(product_attributes)
                        
                            if product_attributes.instance_of?(Hash) && product_attributes.length > 0
                        
                                product.product_attributes = product_attributes
                        
                            else
                               
                                valid = false
                                @success = false
                                @message = "Invalid product attributes"
                                return

                            end
                        
                          rescue  SyntaxError, NameError
                            
                            valid = false
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


                            if valid && !are_product_pictures_valid?(product_pictures)

                                valid = false
                                @success = false
                                @message = "Make sure you uploaded an appropriate pictures with valid extension."
                                return

                            else

                                product.product_pictures = product_pictures

                            end


                        end


                    end



                    if valid

                       product.name = name
                       product.description = description
                       product.price = price.to_d
                       product.main_picture = main_picture
                       product.category_id = category_id
                       product.stock_quantity = stock_quantity.to_i


                       if product.save

                        @success = true
                        @message = "Succesfully created product"

                       else

                        @success = false
                        @message = "Error creating product"

                       end


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

    end

    def get_products

        if current_user.store_user?

            store_user = StoreUser.find_by(store_id: current_user.id)

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


                    cookies.encrypted[:category_id] = category.id


                end



            else

                # user does not own the category 
                # or category deleted

                @success = false

            end

        end

    end

    def search_product

        if current_user.store_user?

            name = params[:name]

            category_id = params[:category_id]

            if name != nil && category_id != nil

                @products = []

                store_user = StoreUser.find_by(store_id: current_user.id)

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

    end

    def remove_product_image

        if current_user.store_user?

            store_user = StoreUser.find_by(store_id: current_user.id)

            category = store_user.categories.find_by(id: params[:category_id])

            if category != nil

                product = category.products.find_by(id: params[:product_id])

                if product != nil

                    image_name = params[:image_name]

                    color_name = params[:color_name]

                    if image_name != nil && image_name.length > 0 && color_name != nil && color_name.length > 0

                        product.remove_image(image_name, color_name)
                        @color_images = product.get_colors_images_map.to_json

                    end



                end


            end


        end

    end

    def store_owns_product_check

        if current_user.store_user?

            store_user = StoreUser.find_by(store_id: current_user.id)

            category_id = params[:category_id]

            category = store_user.categories.find_by(id: category_id)

            if category != nil

                product = category.products.find_by(id: params[:product_id])

                if product != nil

                    @success = true
                    @product = product.to_json
                    @color_images = product.get_colors_images_map.to_json


                else

                    @success = false

                end

            else

                @success = false

            end

        end

    end

    def update_product


        if current_user.store_user?

            store_user = StoreUser.find_by(store_id: current_user.id)

            category_id = params[:category_id]

            product_id = params[:product_id]

            if category_id != nil && product_id != nil


                category = store_user.categories.find_by(id: category_id)

                if category != nil

                    product = category.products.find_by(id: product_id)

                    if product != nil


                        # user owns the product can start updating

                        # PRODUCT NAME VALIDATORS

                        canUpdate = true

                        name = params[:name]
                        description = params[:description]
                        price = params[:price]
                        stock_quantity = params[:stock_quantity]
                        product_available = params[:product_available]
                        product_attributes = params[:product_attributes]
                        main_picture = params[:main_picture]
                        product_pictures = params[:product_pictures]
                        isBase64 = params[:isBase64]
                        

                        if isBase64 != nil

                            isBase64 = eval(isBase64.downcase)

                        end


                        if name != nil && name.length == 0

                            canUpdate = false
                            @success = false
                            @message = "product name cannot be empty"
                            return

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
                                        end

                                    else

                                        canUpdate = false
                                        @success = false
                                        @message = "Invalid main picture"
                                        return


                                    end

                                else

                                    canUpdate = false
                                    @success = false
                                    @message = "Invalid main picture"
                                    return

                                end


                            end



                        else


                            if main_picture != nil  && ( !main_picture.is_a?(ActionDispatch::Http::UploadedFile) || !is_picture_valid?(main_picture))

                                canUpdate = false
                                @success = false
                                @message = "Make sure you uploaded an appropriate picture with valid extension for the main picture."
                                return

                            end


                        end




                        if price != nil

                            if !is_valid_price?(price.to_s)

                                canUpdate = false
                                @success = false
                                @message = "invalid price"
                                return

                            else

                                price = price.to_d

                            end

                        end

                        if stock_quantity != nil

                            # stock quantity can be zero only if product_available is false

                            if !is_positive_integer?(stock_quantity.to_s)

                                canUpdate = false
                                @success = false
                                @message = "Stock quantity must be a positive integer greater than or equal to zero"
                                return

                            else

                                stock_quantity = stock_quantity.to_i

                            end

                        end

                        if product_available != nil

                            if product_available.instance_of?(String)

                                product_available = product_available.downcase

                                if product_available == "false"

                                    product_available = false

                                elsif  product_available == "true"

                                    if stock_quantity == 0

                                        canUpdate = false
                                        @success = false
                                        @message = "Cannot set the product availability on unless the stock quantity is greater zero"
                                        return

                                    elsif stock_quantity > 0

                                        product_available = true

                                    end

                                end


                            else

                                canUpdate = false
                                @success = false
                                @message = "error updating product"
                                return

                            end


                        end

                        if description != nil && description.length == 0

                            canUpdate = false
                            @success = false
                            @message = "description cannot be empty"
                            return

                        end

                        if product_attributes != nil

                            begin

                                product_attributes = eval(product_attributes)

                                if !product_attributes.instance_of?(Hash)

                                    # can be empty hash

                                    canUpdate = false
                                    @success = false
                                    @message = "Invalid product attributes"
                                    return

                                end

                            rescue  SyntaxError, NameError

                                canUpdate = false
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

                                    canUpdate = false
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





                        if canUpdate


                            if name != nil
                                product.name = name
                            end

                            if main_picture != nil
                                product.main_picture = main_picture
                            end

                            if price != nil
                                product.price = price
                            end

                            if stock_quantity != nil
                                product.stock_quantity = stock_quantity
                            end

                            if description != nil
                                product.description = description
                            end

                            if product_attributes != nil
                                product.product_attributes = product_attributes
                            end


                            if product_available != nil
                                product.product_available = product_available
                            end

                            
                            if product.save!

                                @success = true
                                @message = "Updated product"
                                @product = product.to_json

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


        end

    end


    def import_products

        if current_user.store_user?

            store_user = StoreUser.find_by(store_id: current_user.id)
            category = store_user.categories.find_by(id: params[:category_id])

            if category != nil

               pictures = params[:product_pictures]

               file = params[:file]

               isBase64 = params[:isBase64]

               canImport = true


               if category.subcategories.length > 0

                   canImport = false
                   @success = false
                   @message = "Cannot import products since category already has subcategories."

                   return

               end


               if file == nil || !file.is_a?(ActionDispatch::Http::UploadedFile) || !is_csv_file_valid?(file)

                   canImport = false
                   @success = false
                   @message = "The file to import products must be of type csv."
                   return

               end

               if  pictures == nil || !pictures.instance_of?(Array)

                   canImport = false
                   @success = false
                   @message = "Upload pictures to continue"

               end

                # Even if the user might have uploaded extra pictures, or if there are some missing pictures,
                #  or if there are some pictures of invalid type
                #  proceed and try to make as much as valid products as possible
                #  then you can report to the user how many products were imported
                #  and the names of those that failed to import so he can re import them

               if canImport

                   if isBase64 != nil

                       isBase64 = eval(isBase64.downcase)

                       if isBase64 == true
                           pictures = decode_base64_pictures(pictures)
                       end

                   end

                   canCreate = true

                   csv_file = file.tempfile.open

                   filepath = csv_file.path

                   csv = CSV.read(filepath, headers: true, converters: :numeric)

                   csv_header_map = get_csv_file_header_map(csv)

                   # make sure all headers are present

                   csv_header_map.values.each do |value|

                       if value.empty?
                           canCreate = false
                           @success = false
                           @message = "Make sure your csv file has all of the following headers: name, description, price, main picture and stock quantity"
                           csv_file.close
                           return
                       end

                   end

                   if canCreate


                       csv.each do |row|

                           canSave = true


                           name = row[ csv_header_map[:name] ]
                           description = row[ csv_header_map[:description] ]
                           price = row[ csv_header_map[:price] ]
                           main_picture = get_uploaded_picture(pictures, row[ csv_header_map[:main_picture] ] )
                           stock_quantity = row[ csv_header_map[:stock_quantity] ]

                           if name == nil || name.length == 0
                               canSave = false
                           end

                           if canSave && ( description == nil || description.length == 0 )
                               canSave = false
                           end

                           if canSave &&   ( price == nil || !is_valid_price?(price.to_s) )
                               canSave = false
                           else
                               price = price.to_d
                           end


                           if isBase64 != nil &&  isBase64

                               if canSave && main_picture == nil
                                   canSave = false
                               end

                           else

                               if canSave &&  (  main_picture == nil || !main_picture.is_a?(ActionDispatch::Http::UploadedFile) || !is_picture_valid?(main_picture))
                                   canSave = false
                               end

                           end



                           if canSave  && ( stock_quantity == nil || !is_positive_integer?(stock_quantity.to_s) || stock_quantity.to_i == 0 )
                               canSave = false
                           else
                               stock_quantity = stock_quantity.to_i
                           end


                           if canSave

                               # All other columns add them to the product attributes

                               # Make sure that the other headers are not the required headers

                               #  or that they resemble that required headers in some way

                               product_attributes = {}
                               product_pictures = []
                               required_headers = csv_header_map.values


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

                                           if !required_headers.include?(header) &&
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

                                   ActionCable.server.broadcast "category_#{category.id}_products_user_#{current_user.id}", {products: new_products}

                               end


                           end





                       end

                       @success = true

                       #products = []
                       #
                       #category.products.each do |product|
                       #    products.push(product.to_json)
                       #end
                       #
                       #@products = products

                       csv_file.close


                   end






               end






            end


        end

    end

    private

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

                if header.include?("name") && header_map[:name].empty?
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

        header.include?("pictures") ||
            header.include?("images") ||
            header.include?("photos") ||
            header.include?("pics") ||
            header.include?("imgs")

    end

    def description_contains(header)

            header.include?("description") ||
            header.include?("information")  ||
            header.include?("info") ||
            header.include?("about") ||
            header.include?("detail")

    end

    def price_contains(header)

            header.include?("price") ||
            header.include?("cost")


    end

    def main_picture_contains(header)

            header.include?("picture") ||
            header.include?("image") ||
            header.include?("photo") ||
            header.include?("thumbnail")
    end

    def stock_quantity_contains(header)

            header.include?("stock") ||
            header.include?("quantity") ||
            header.include?("qty")

    end

    def is_csv_file_valid?(file)

        filename = file.original_filename.split(".")
        extension = filename[filename.length - 1]
        valid_extensions = ["csv"]
        valid_extensions.include?(extension)


    end

    def is_positive_integer?(arg)
     
        res = /^(?<num>\d+)$/.match(arg)
   
        if res == nil
           false
        else
           true
        end
   
    end

    def is_valid_price?(arg)
        
        # price must be a number greater than 0

        if /^\d+([.]\d+)?$/.match(arg) == nil
          false
        else

            arg = arg.to_d

            if arg == 0
                false
            else
                true
            end
         
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

   

end
