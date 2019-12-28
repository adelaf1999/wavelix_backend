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
                :product_pictures_attributes,
                {product_pictures: []}
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
                
                product_pictures_attributes = product_params[:product_pictures_attributes]
                
                product_pictures = product_params[:product_pictures]
                
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

                    # validate product pictures as neccesary

                    if product_pictures != nil


                        if valid && !are_product_pictures_valid?(product_pictures)

                            valid = false
                            @success = false
                            @message = "Make sure you uploaded an appropriate pictures with valid extension."
                            return

                        else

                            product.product_pictures = product_pictures

                        end

                    end


                    
                    if product_pictures == nil &&  product_pictures_attributes != nil

                        valid = false
                        @success = false
                        @message = "Upload product pictures to continue"
                        return

                    elsif product_pictures != nil && product_pictures_attributes == nil

                        valid = false
                        @success = false
                        @message = "State the product pictures attributes to continue"
                        return

                    elsif product_pictures != nil && product_pictures_attributes != nil


                        product_pictures_filenames = []

                        product_pictures.each do |picture|

                            # include the picture extension
                            product_pictures_filenames.push(picture.original_filename)

                        end


                        if valid && !are_product_pictures_attributes_valid?(product_pictures_filenames, product_pictures_attributes)

                            valid = false
                            @success = false
                            @message = "Error uploading product pictures"
                            return


                        else

                            product_pictures_attributes = eval(product_pictures_attributes)

                            product.product_pictures_attributes = product_pictures_attributes

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

    def are_product_pictures_attributes_valid?(product_pictures_filenames, product_pictures_attributes)

        begin

            product_pictures_attributes = eval(product_pictures_attributes)
        
            if product_pictures_attributes.instance_of?(Hash) && product_pictures_attributes.length > 0
        
                attributes_valid = true
        
                product_pictures_attributes.values().each do |attribute|
        
                    if attributes_valid
        
                        if attribute.instance_of?(Hash)
        
                            if attribute.length > 0
        
                                attribute.values().each do |v|
                            
                                    if !v.instance_of?(String) || !product_pictures_filenames.include?(v)
                                        attributes_valid = false
                                        break
                                    end
                
                                end
        
                            else
        
                                attributes_valid = false
                                break
        
                            end
        
        
                        elsif !attribute.instance_of?(String) || !product_pictures_filenames.include?(attribute)
                            attributes_valid = false
                            break
                        end
        
                    else
        
                        break
        
                    end
        
                end
        
        
                attributes_valid
        
            else
        
                false
        
            end
        
          rescue  SyntaxError, NameError
        
            false
        
        end

    end

end
