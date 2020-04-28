class LikesController < ApplicationController

  before_action :authenticate_user!

  def create

    # unverified stores cannot like

    # can like once and only once

    post = Post.find_by(id: params[:post_id])

    if post != nil

      if current_user.store_user?

        store_user = StoreUser.find_by(store_id: current_user.id)

        if store_user.verified?

          like = post.likes.find_by(liker_id: current_user.id)

          if like.nil?

            Like.create!(post_id: post.id, liker_id: current_user.id)

            @success = true

            current_user_profile = current_user.profile

            post_profile = post.profile

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

        else

          @success = false

        end


      end


    else

      @success = false


    end

  end

end
