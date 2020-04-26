class CommentController < ApplicationController

  before_action :authenticate_user!

  def create

    # unverified stores cannot comment

    post = Post.find_by(id: params[:post_id])

    text = params[:text]

    if post != nil && text != nil

      text = text.strip

      if text.length > 0


        if current_user.store_user?

          store_user = StoreUser.find_by(store_id: current_user.id)

          if store_user.verified?

            Comment.create!(post_id: post.id, author_id: current_user.id, text: text)

            @success = true

          else

            @success = false

          end

        else

          Comment.create!(post_id: post.id, author_id: current_user.id, text: text)

        end


      else

        @success = false


      end

    else

      @success = false

    end

  end

end
