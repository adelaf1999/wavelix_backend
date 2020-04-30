class CommentController < ApplicationController

  include PostHelper

  before_action :authenticate_user!

  def destroy

    comment = Comment.find_by(id: params[:comment_id])

    post = Post.find_by(id: params[:post_id])

    if comment != nil && post != nil

      current_user_profile = current_user.profile

      if current_user_profile.posts.find_by(id: post.id) != nil && comment.post_id == post.id

        # The current user owns the post and therefore can delete the comment

        @success = true

        send_my_posts


      elsif comment.author_id == current_user.id && comment.post_id == post.id

        @success = true

        post_profile = post.profile

        post_user = post_profile.user

        posts = []

        post_profile.posts.order(created_at: :desc).each do |p|
          posts.push(p.get_attributes)
        end

        @posts = posts.to_json

        ActionCable.server.broadcast "post_channel_#{post_user.id}", {posts: @posts}

        ActionCable.server.broadcast "profile_channel_#{post_profile.id}", {posts: @posts}



      else


        @success = false


      end




    else


      @success = false


    end




  end

  def create

    # unverified stores cannot comment

    post = Post.find_by(id: params[:post_id])

    text = params[:text]

    if post != nil && text != nil

      text = text.strip

      if text.length > 0

        current_user_profile = current_user.profile

        post_profile = post.profile

        post_user = post_profile.user

        if current_user.store_user?

          store_user = StoreUser.find_by(store_id: current_user.id)

          if store_user.verified?

            create_comment(current_user_profile, post_profile, post_user, post, text)

          else

            @success = false

          end

        else


          create_comment(current_user_profile, post_profile, post_user, post, text)


        end


      else

        @success = false


      end

    else

      @success = false

    end

  end


  private


  def create_comment(current_user_profile, post_profile, post_user, post, text)


    if post_profile.private_account?

      following_relationship = current_user.following_relationships.find_by(followed_id: post_user.id)

      if following_relationship.nil?

        @success = false

      else

        if following_relationship.active?

          @success = true

          Comment.create!(post_id: post.id, author_id: current_user.id, text: text)

          send_posts(current_user_profile, post_profile)

        else

          @success = false

        end



      end

    else

      @success = true

      Comment.create!(post_id: post.id, author_id: current_user.id, text: text)

      send_posts(current_user_profile, post_profile)


    end


  end


end
