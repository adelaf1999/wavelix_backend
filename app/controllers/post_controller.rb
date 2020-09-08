class PostController < ApplicationController

  include ProfileHelper

  include PostHelper

  before_action :authenticate_user!

  def search_post_products

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      name = params[:name]

      @products = []

      if name != nil

        products = store_user.products.where("name ILIKE ?", "%#{name}%").order('name ASC')

        products.each do |product|

          item = {}

          item[:id] = product.id

          item[:name] = product.name

          item[:main_picture] = product.main_picture.url

          item[:price] = product.price

          item[:currency] = product.currency

          if product.product_available == false || product.stock_quantity == 0

            item[:can_post] = false

          else

            item[:can_post] = true

          end

          @products.push(item)


        end


      end

    end


  end


  def destroy

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end


    # can destroy profile / story post

    profile = current_user.profile

    post = profile.posts.find_by(id: params[:post_id])

    if post != nil

      post.destroy!

      @success = true

      send_my_posts

    else

      # post deleted or doest not belong to current user

      @success = false

      send_my_posts


    end


  end


  def edit_profile_post

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end

    profile = current_user.profile

    post = profile.posts.find_by(id: params[:post_id])

    if post != nil && !post.is_story

      # can edit caption (if added)

      caption = params[:caption]

      if caption != nil

        caption = caption.strip

        post.update!(caption: caption)

      end

      @success = true

      send_my_posts


    else

      # post deleted or doest not belong to current_user profile

      @success = false

      send_my_posts

    end


  end

  def create

    if current_user.store_user?

      store_user = StoreUser.find_by(store_id: current_user.id)

      if store_user.unverified?

        @success = false
        @message = "You need to be verified to create post"
        return

      end

    elsif current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end


    end

    # store users can only create post / story if verified

    profile = current_user.profile

    media_file = params[:media_file]

    is_story = params[:is_story]

    product_id = params[:product_id]

    if media_file == nil || !media_file.is_a?(ActionDispatch::Http::UploadedFile) || !is_media_file_valid?(media_file)

      @success = false
      @message = "Upload a media file with appropriate extension and try again"


    else

      post = Post.new

      post.profile_id = profile.id

      media_type = get_media_file_type(media_file)

      post.media_type = media_type

      caption = params[:caption]

      if caption != nil && caption.length > 0

        post.caption = caption

      end

      if is_story != nil

        is_story = eval(is_story.downcase)

        if is_story

          post.is_story = true

        end

      end


      if current_user.store_user? && !product_id.nil?

        store_user = StoreUser.find_by(store_id: current_user.id)

        product = store_user.products.find_by(id: product_id)

        if product != nil

          if product.product_available && product.stock_quantity != 0

            post.product_id = product_id

          end


        end


      end


      if media_type == 0

        # The user will wait till his image is uploaded and encoded


        if post.save!

          post.image_file = media_file

          if post.delay.save!

            post.complete!


            @success = true

            if post.is_story
            
              Delayed::Job.enqueue(StoryJob.new(post.id, current_user.id), queue: 'delete_story_post_queue', priority: 0, run_at: 24.hours.from_now)

            end


            PostBroadcastJob.perform_later(current_user.id)


            return

          end

        else

          @success = false
          @message = "Error creating post"
          return

        end


      else



        video = FFMPEG::Movie.new(media_file.tempfile.path)

        thumbnail_filename = "#{Time.now.to_i}.jpeg"

        thumbnail_path = "#{Rails.root}/tmp/#{thumbnail_filename}"

        video.screenshot(thumbnail_path, seek_time: 1)

        thumbnail_tempfile = File.new(thumbnail_path)


        video_thumbnail = ActionDispatch::Http::UploadedFile.new({
                                                                     tempfile: thumbnail_tempfile,
                                                                     type: 'image/jpeg',
                                                                     filename: thumbnail_filename
                                                                 })

        post.video_thumbnail = video_thumbnail

        if post.save!

          File.delete(thumbnail_path) if File.exist?(thumbnail_path)

          @success = true

          PostBroadcastJob.perform_later(current_user.id)


          local_video = LocalVideo.new

          local_video.video = media_file

          if local_video.save!

            post_id = post.id

            local_video_id = local_video.id

            user_id = current_user.id

            Delayed::Job.enqueue(
                CompressVideoJob.new(post_id, local_video_id, user_id),
                queue: 'compress_video_queue',
                priority: 0
            )

            return

          end

        else

          @success = false
          @message = "Error creating post"
          return

        end

      end


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
