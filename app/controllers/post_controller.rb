class PostController < ApplicationController
  include ProfileHelper

  before_action :authenticate_user!

  def create

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      if store_user.verified?

        # can only create post if verified

        profile = current_user.profile

        media_file = params[:media_file]

        if media_file == nil || !media_file.is_a?(ActionDispatch::Http::UploadedFile) || !is_media_file_valid?(media_file)
          @success = false
          @message = "Upload a media file with appropriate extension and try again"
          return
        else

          post = Post.new
          post.profile_id = profile.id
          post.media_type = get_media_file_type(media_file)
          post.media_file = media_file

          caption = params[:caption]
          #category_id = params[:category_id]
          #product_id = params[:product_id]

          if caption != nil && caption.length > 0

            post.caption = caption

          end

          #if category_id != nil && product_id != nil
          #
          #  # make sure store owns the product
          #
          #  category = store_user.categories.find_by(id: category_id)
          #
          #  if category != nil
          #
          #    product = category.products.find_by(id: product_id)
          #
          #    if product != nil
          #
          #      post.product_id = product_id
          #
          #    end
          #
          #  end
          #
          #end

          if post.save!

            @success = true
            @message = "Successfully created post"
            profile = current_user.profile
            @posts = get_posts(profile).to_json

            return
          else
            @success = false
            @message = "Error creating post"
            return
          end


        end


      else

        @success = false
        @message = "You need to be verified to create post"
        return

      end

    else

    end

  end


  private

  def is_media_file_valid?(media_file)

    filename = media_file.original_filename.split(".")
    extension = filename[filename.length - 1]
    valid_extensions = ["png" , "jpeg", "jpg", "gif", "flv", "avi", "mp4", "wmv", "mov", "mkv", "3gp"]
    valid_extensions.include?(extension)

  end

  def get_media_file_type(media_file)

    filename = media_file.original_filename.split(".")

    extension = filename[filename.length - 1]

    image_extensions = ["png" , "jpeg", "jpg", "gif"]

    video_extensions = ["flv", "avi", "mp4", "wmv", "mov", "mkv", "3gp"]

    if image_extensions.include?(extension)
      0
    elsif video_extensions.include?(extension)
      1
    end


  end

end
