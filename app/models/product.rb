class Product < ApplicationRecord

   validates_presence_of :name, :description, :price, :main_picture, :category_id, :stock_quantity

   mount_uploader :main_picture, ImageUploader

   mount_uploaders :product_pictures, ImageUploader

   belongs_to :category

   serialize :product_attributes, Hash

   serialize :product_pictures, Array

   serialize :product_pictures_attributes, Hash

   def decrement_stock_quantity(amount)
        # amount must be an integer
       if is_positive_integer?(amount.to_s)
            
            amount = amount.to_i
            
            if amount > 0 && (amount <= self.stock_quantity )

                # prevent stock quantity from being negative and make sure its greater than 0

                stock_quantity = self.stock_quantity - amount

                if stock_quantity == 0
                    self.update!(product_available: false, stock_quantity: stock_quantity )
                else
                    self.update!(stock_quantity: stock_quantity)
                end

            end
       
        end
   end

   def get_colors_images_map

     # red: [ { uri: , image_name: , color_name:  }  ]

     colors_images = {}

     self.product_pictures_attributes.each do |color_name, images_names|

       images_names.each do |image_name|

         # any image uri can be used even if its in another color

         image_index = find_image_index(self.product_pictures, image_name )

         uri = self.product_pictures[image_index].url

         if colors_images.has_key?(color_name)

           images = colors_images[color_name]

           images.push({ uri: uri, image_name: image_name, color_name: color_name })

           colors_images[color_name] = images

         else

           image = [{ uri: uri, image_name: image_name, color_name: color_name }]
           colors_images[color_name] = image

         end



       end


     end

     colors_images


   end

   def remove_image(image_name, color_name)

     # image index is the image index in the product_pictures array

     color_name = color_name.to_sym

     # Remove Image from product pictures

     deleted_image = self.product_pictures.delete_at(find_image_index(self.product_pictures, image_name) || self.product_pictures.length)

     deleted_image.try(:remove!)

     # Remove Image from product pictures attributes

     image_names = self.product_pictures_attributes[color_name]

     if image_names.length == 1

       self.product_pictures_attributes.delete(color_name)

     else

       image_names.delete_at(image_names.index(image_name) || image_names.length)

       self.product_pictures_attributes[color_name] = image_names

     end

     self.save


   end

   private

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
