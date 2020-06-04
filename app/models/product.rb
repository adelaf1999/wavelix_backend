class Product < ApplicationRecord

   validates_presence_of :name, :price, :main_picture, :category_id

   mount_uploader :main_picture, ImageUploader

   mount_uploaders :product_pictures, ImageUploader

   belongs_to :category

   serialize :product_attributes, Hash

   serialize :product_pictures, Array
   

   before_create :add_store_attributes


   def can_buy?(user)

     # Stores cannot buy products

     # Product cannot be bought if stock quantity is 0 or is not available

     # Customer cannot buy product if its not in his country

     # Customers can only buy products from verified stores


     if user.store_user? || self.stock_quantity == 0 || !self.product_available

       false

     elsif user.customer_user?

       customer_user = CustomerUser.find_by(customer_id: user.id)

       store_user = self.category.store_user


       if store_user.verified?

         customer_user.country == self.store_country

       else

         false

       end



     end

   end

   def decrement_stock_quantity(amount)
        # amount must be an integer
       if is_positive_integer?(amount.to_s)
            
            amount = amount.to_i
            
            if amount > 0 && (amount <= self.stock_quantity )

                # prevent stock quantity from being negative and make sure its greater than 0

                stock_quantity = self.stock_quantity - amount

                self.update!(stock_quantity: stock_quantity)

                # if stock_quantity == 0
                #     self.update!(product_available: false, stock_quantity: stock_quantity )
                # else
                #     self.update!(stock_quantity: stock_quantity)
                # end

            end
       
        end
   end


   def remove_image(image_name)

     # image index is the image index in the product_pictures array

     # Remove Image from product pictures

     deleted_image = self.product_pictures.delete_at(find_image_index(self.product_pictures, image_name) || self.product_pictures.length)

     deleted_image.try(:remove!)

     self.save


   end


   def get_images

     images = []

     self.product_pictures.each do |picture|

       images.push({
                       uri: picture.url,
                       image_name: picture.file.filename
                   })

     end

     images


   end

   private

   def add_store_attributes

     store_user = Category.find_by(id: self.category_id).store_user

     self.currency = store_user.currency

     self.store_country = store_user.store_country

   end



   def find_image_index(images, image_name)

     image_names = []

     images.each do |image|
       image_names.push(image.file.filename)
     end


     image_names.index(image_name)

   end

   def is_positive_integer?(arg)
     
     res = /^(?<num>\d+)$/.match(arg)

     if res == nil
        false
     else
        true
     end

   end


end
