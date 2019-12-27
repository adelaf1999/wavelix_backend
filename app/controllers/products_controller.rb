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
                :product_attributes
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

                category = store_user.categories.find_by(id: category_id)

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

                        if is_number?(price.to_s)

                            price = price.to_d 

                            if price == 0
                            
                                valid = false
                                @success = false
                                @message = "Invalid price"
                                return

                            end

                        else

                            valid = false
                            @success = false
                            @message = "Invalid price"

                            return

                        end


                    end


                    if valid && ( !main_picture.is_a?(ActionDispatch::Http::UploadedFile) || !is_main_picture_valid?(main_picture) )

                        valid = false
                        @success = false
                        @message = "Make sure you uploaded an appropriate picture with valid extension."

                        return

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

                    # validate and modify product_attributes as necessary

                    if product_attributes != nil

                        product_attributes = validate_and_modify_product_attributes(product_attributes)

                        if valid &&  product_attributes == false 

                            valid = false
                            @success = false
                            @message = "Invalid product attributes"

                            return

                        else

                            product.product_attributes = product_attributes

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

    private

    def validate_and_modify_product_attributes(product_attributes)



        begin

            product_attributes = eval(product_attributes)
        
            if product_attributes.instance_of?(Hash) && product_attributes.length > 0
        
                product_attributes.each  do |key, value|
        
                    value = value.to_s.strip
        
                    if value.include?(",") && !value.include?(" ")  && value.length >= 3
                        # list can't contain duplicates
                        product_attributes[key] = value.split(",").uniq
                    elsif value.include?(":") && value.count(":") == 1 && value.length >= 3
                        
                        numbers = []
                        
                        range_array = value.split(":")
                        
                        min = range_array[0]
                        
                        max = range_array[1]
                    
                        if is_positive_integer?(min) && is_positive_integer?(max)
                            
                            # can be 0 or more
        
                            min = min.to_i
        
                            max = max.to_i

                            # min and max cant be equal
        
                            if max > min
        
                                for i in min..max
                                    numbers.push(i)
                                end
            
                                product_attributes[key] = numbers
        
                            end
        
                            
        
                        end
        
                    end
                    
        
                end
        
                product_attributes
        
            else
                # p "Not a hash"
                false
            end
        
          rescue  SyntaxError, NameError
             false
          end

    end


    def is_positive_integer?(arg)
     
        res = /^(?<num>\d+)$/.match(arg)
   
        if res == nil
           false
        else
           true
        end
   
    end

    def is_number?(arg)
        if /^\d+([.]\d+)?$/.match(arg) == nil
          false
        else
          true
        end
    end

    def is_main_picture_valid?(main_picture)

        filename = main_picture.original_filename.split(".")
        extension = filename[filename.length - 1]
        valid_extensions = ["png" , "jpeg", "jpg", "gif"]
        valid_extensions.include?(extension)

    end

end
