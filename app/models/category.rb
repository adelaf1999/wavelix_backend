class Category < ApplicationRecord

    # all categories and subcategories and their products are destroyed

    validates_presence_of :name, :store_user_id
    has_many :subcategories, class_name: 'Category', foreign_key: 'parent_id', dependent: :destroy
    has_many :products
    belongs_to :parent, class_name: 'Category', optional: true 
    belongs_to :store_user
    before_destroy :destroy_all_products

    private

    def destroy_all_products
        if self.products.length > 0
            self.products.destroy_all 
        end
    end
    

end
