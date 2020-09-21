class LikesController < ApplicationController

  include PostHelper

  include HomeHelper

  before_action :authenticate_user!


  def destroy

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

    post = Post.find_by(id: params[:post_id])

    if post != nil

      like = post.likes.find_by(liker_id: current_user.id)

      if like != nil

        like.destroy!

        @success = true

        current_user_profile = current_user.profile

        post_profile = post.profile

        send_posts(current_user_profile, post_profile)

        send_profile_posts_home_page(params[:post_category], current_user)


      end

    end


  end

  def create

    # unverified stores cannot like

    # cannot like posts of private account unless following them

    # can like once and only once profile posts only

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

    post = Post.find_by(id: params[:post_id])

    if post != nil && !post.is_story

      if current_user.store_user?

        store_user = StoreUser.find_by(store_id: current_user.id)

        if store_user.verified?

          like = post.likes.find_by(liker_id: current_user.id)

          if like.nil?

            current_user_profile = current_user.profile

            post_profile = post.profile

            post_user = post_profile.user

            if post_profile.private_account?


              following_relationship = current_user.following_relationships.find_by(followed_id: post_user.id)

              if following_relationship.nil?

                @success = false

              else

                if following_relationship.active?

                  @success = true

                  Like.create!(post_id: post.id, liker_id: current_user.id)

                  send_posts(current_user_profile, post_profile)

                  send_profile_posts_home_page(params[:post_category], current_user)


                else

                  @success = false

                end



              end

            else

              @success = true

              Like.create!(post_id: post.id, liker_id: current_user.id)

              send_posts(current_user_profile, post_profile)

              send_profile_posts_home_page(params[:post_category], current_user)


            end



          else

            @success = false

          end

        else

          @success = false

        end

      else


        like = post.likes.find_by(liker_id: current_user.id)

        if like.nil?

          Like.create!(post_id: post.id, liker_id: current_user.id)

          @success = true

          current_user_profile = current_user.profile

          post_profile = post.profile

          send_posts(current_user_profile, post_profile)

          send_profile_posts_home_page(params[:post_category], current_user)
          

        else

          @success = false

        end


      end


    else

      @success = false


    end

  end




end
