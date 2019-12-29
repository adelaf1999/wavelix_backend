class StoreUser < ApplicationRecord

    belongs_to :store, touch: true
    mount_uploader :store_business_license, BusinessLicenseUploader
    serialize :store_address, Hash
    has_many :categories

    enum status: {unverified: 0, verified: 1}

   

    def get_categories

        categories = []

        self.categories.each do |category|

            if category.parent_id == nil


                parent_category = {name: category.name, id: category.id, parent_id: category.parent_id}

                if category.products.length > 0

                    parent_category[:has_products] = true

                else

                    parent_category[:has_products] = false

                end

                child_categories = category.subcategories

                if child_categories.length > 0

                    parent_category[:has_subcategories] = true

                    parent_category_subcategories = get_child_subcategories(child_categories, category)

                    parent_category[:subcategories] = parent_category_subcategories

                    categories.push(parent_category)

                else

                    parent_category[:has_subcategories] = false

                    categories.push(parent_category)

                end

            end

        end

        categories

    end


    private

    def get_child_subcategories(subcategories, parent_category)

        categories = []

        subcategories.each do |subcategory|

            new_parent_category = { name: subcategory.name, id: subcategory.id, parent_id: subcategory.parent_id }


            if subcategory.products.length > 0

                new_parent_category[:has_products] = true

            else

                new_parent_category[:has_products] = false

            end

            child_categories = subcategory.subcategories

            if child_categories.length > 0

                new_parent_category[:has_subcategories] = true

                new_parent_subcategories = get_child_subcategories(child_categories, subcategory)

                new_parent_category[:subcategories] = new_parent_subcategories

                categories.push(new_parent_category)

            else

                new_parent_category[:has_subcategories] = false

                categories.push(new_parent_category)

            end

        end

        categories

    end

end
