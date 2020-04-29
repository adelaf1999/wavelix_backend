class LikesController < ApplicationController

  before_action :authenticate_user!


  def destroy

    post = Post.find_by(id: params[:post_id])

    if post != nil

      like = post.likes.find_by(liker_id: current_user.id)

      if like != nil

        like.destroy!

        @success = true

        current_user_profile = current_user.profile

        post_profile = post.profile

        send_posts(current_user_profile, post_profile)


      end

    end


  end

  def create

    # unverified stores cannot like

    # cannot like posts of private account unless following them

    # can like once and only once

    post = Post.find_by(id: params[:post_id])

    if post != nil

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

                @success = true

                Like.create!(post_id: post.id, liker_id: current_user.id)


                send_posts(current_user_profile, post_profile)


              end

            else

              @success = true

              Like.create!(post_id: post.id, liker_id: current_user.id)


              send_posts(current_user_profile, post_profile)


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

        else

          @success = false

        end


      end


    else

      @success = false


    end

  end


  private


  def send_posts(current_user_profile, post_profile)

    if current_user_profile.id == post_profile.id

      posts = []

      current_user_profile.posts.each do |p|
        posts.push(p.get_attributes)
      end

      @posts = posts.to_json

      ActionCable.server.broadcast "post_channel_#{current_user.id}", {posts: @posts}

    else


      posts = []

      post_profile.posts.each do |p|
        posts.push(p.get_attributes)
      end

      @posts = posts.to_json

      ActionCable.server.broadcast "profile_channel_#{post_profile.id}", {posts: @posts}


    end

  end

end
