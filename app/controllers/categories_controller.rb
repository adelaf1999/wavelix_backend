class CategoriesController < ApplicationController

    # before_action :authenticate_user!

    before_action :deny_to_visitors

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


        category_name = params[:category_name]

        if category_name != nil && category_name.length > 0

            category = Category.new

            category.name = category_name
            category.store_user_id = store_user.id

            if category.save

                @success = true
                @message = 'Successfully created category'
                @categories = store_user.get_categories


            else

                @success = false
                @message = 'Error creating category'


            end

        else

            @success = false
            @message = 'Category Name cannot be empty'


        end



    end

    def get_categories


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



        @categories = store_user.get_categories




    end

    def change_category_name



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

            # store owns this category

            category_name = params[:category_name]

            if category_name != nil && category_name.length > 0

                category.update!(name: category_name)

                @success = true
                @message = "Successfully changed category name"
                @categories = store_user.get_categories


            else

                @success = false
                @message = "Invalid category name"

            end

        else

            @success = false
            @message = "Category may have been moved or deleted"


        end






    end

    def add_subcategory


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

        # Cant create subcategory if category has products

        category = store_user.categories.find_by(id: params[:category_id])

        if category != nil


            if category.products.length > 0

                @success = false
                @message = "Cannot add subcategory since category already has products"

            else

                category_name = params[:category_name]



                if category_name != nil && category_name.length > 0

                    # Category.create!(name: category_name, store_user_id: store_user.id, parent_id: category.id)
                    new_subcategory = Category.new
                    new_subcategory.name = category_name
                    new_subcategory.store_user_id = store_user.id
                    new_subcategory.parent_id = category.id

                    if new_subcategory.save
                        @success = true
                        @message = "Successfully added subcategory"
                        @categories = store_user.get_categories
                    else

                        @success = false
                        @message = "Error adding subcategory"

                    end



                else

                    @success = false
                    @message = "Invalid category name"

                end


            end

        else

            @success = false
            @message = "Category may have been moved or deleted"

        end



    end

    def store_has_category


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

                @has_subcategories = true

            else

                @has_subcategories = false

            end

            @success = true

            @minimum_product_price = store_user.get_minimum_product_price

            @maximum_product_price = store_user.get_maximum_product_price

        else

            @success = false

        end


    end


    private

    def traverse_child_subcategories(subcategories, parent_node, parent_category)

        store_user = StoreUser.find_by(store_id: current_user.id)

        for i in 0..subcategories.length

            subcategory = subcategories[i]

            if subcategory != nil


                child_node = subcategory[:name]

                if child_node != nil && child_node.length > 0

                    # p "hey i am #{child_node} my parent is #{parent_node}"
                    child_subcategories = subcategory[:subcategories]

                    if child_subcategories != nil && child_subcategories.length > 0
                        new_parent_category = Category.create!(
                            name: child_node,
                            store_user_id: store_user.id,
                            parent_id: parent_category.id
                        )
                        traverse_child_subcategories(child_subcategories, child_node, new_parent_category)
                    else
                        Category.create!(
                            name: child_node,
                            store_user_id: store_user.id,
                            parent_id: parent_category.id
                        )

                    end

                end



            end

        end

    end

    def traverse_data(data)

        root_node = data[:name]

        store_user = StoreUser.find_by(store_id: current_user.id)


        if root_node != nil && root_node.length > 0

            subcategories = data[:subcategories]

            if subcategories != nil

                if subcategories.length > 0

                    root_category =  Category.create!(
                        name: root_node,
                        store_user_id: store_user.id
                    )

                    for i in 0..subcategories.length

                        subcategory = subcategories[i]

                        if subcategory != nil

                            child_node = subcategory[:name]


                            if child_node != nil && child_node.length > 0

                                # p "hey i am #{child_node} my parent is #{root_node}"
                                child_subcategories = subcategory[:subcategories]

                                if child_subcategories != nil && child_subcategories.length > 0

                                    new_parent_category = Category.create!(
                                        name: child_node,
                                        store_user_id: store_user.id,
                                        parent_id: root_category.id
                                    )

                                    traverse_child_subcategories(child_subcategories, child_node, new_parent_category)

                                else
                                    Category.create!(
                                        name: child_node,
                                        store_user_id: store_user.id,
                                        parent_id: root_category.id
                                    )
                                end

                            end

                        end

                    end

                end

            else

                Category.create!(name: root_node, store_user_id: store_user.id)

            end

        end


    end


    def deny_to_visitors

        head :unauthorized unless user_signed_in? or employee_signed_in?

    end



end