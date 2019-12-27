class CategoriesController < ApplicationController

    before_action :authenticate_user!

    def create

        if current_user.store_user?

            categories = eval(params[:categories])

            if categories != nil
                traverse_data(categories)
            end

        end

    end

    def get_categories

        if current_user.store_user?

            @categories = StoreUser.find_by(store_id: current_user.id).get_categories

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


    end