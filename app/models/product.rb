class Product < ApplicationRecord

   validates_presence_of :name, :description, :price, :main_picture, :category_id, :stock_quantity

#    mount_uploader :main_picture, ImageUploader

   belongs_to :category

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

   private

   def is_positive_integer?(arg)
     
     res = /^(?<num>\d+)$/.match(arg)

     if res == nil
        false
     else
        true
     end

   end


end
