class CommentController < ApplicationController

  include PostHelper

  before_action :authenticate_user!

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
