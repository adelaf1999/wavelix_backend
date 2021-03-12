class PostController < ApplicationController

  include ProfileHelper

  include PostHelper

  include HomeHelper

  include PostCaseHelper

  before_action :authenticate_user!

  def add_story_post_viewer

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end


    post = Post.find_by(id: params[:post_id])

    if post != nil

      if post.is_story

        viewers_ids = post.get_viewers_ids

        if !viewers_ids.include?(current_user.id)

          @success = true

          viewers_ids.push(current_user.id)

          post.update!(viewers_ids: viewers_ids)

          send_stories_to_home_page(current_user)

          profile_owner_user_id = post.profile.user.id

          PostBroadcastJob.perform_later(profile_owner_user_id)


        else

          @success = false

        end


      else

        @success = false

      end


    else

      @success = false

    end


  end

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

      destroy_post_case(post)

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

        # store users can only create post if verified

        @success = false

        @message = 'You need to be verified to create post'

        return

      end

    elsif current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      if !customer_user.phone_number_verified?

        @success = false

        return

      end

    end


    profile = current_user.profile


    if profile.blocked?

      @success = false

      @message = "Couldn't create post since profile has been blocked"

    else


      media_file = params[:media_file]

      is_story = params[:is_story]

      product_id = params[:product_id]

      base64 = params[:base64]


      if !media_file.blank? && !base64.blank?

        base64 = eval(base64)

        post = Post.new

        post.profile_id = profile.id


        caption = params[:caption]

        if !caption.blank?

          post.caption = caption

        end

        if !is_story.blank?

          is_story = eval(is_story.downcase)

          if is_story

            post.is_story = true

          end

        end


        if current_user.store_user? && !product_id.blank?

          store_user = StoreUser.find_by(store_id: current_user.id)

          product = store_user.products.find_by(id: product_id)

          if product != nil

            if product.product_available && product.stock_quantity != 0

              post.product_id = product_id

            end


          end


        end


        # Validate and configure the media file based on whether its base64 or not

        if base64

          media_file = eval(media_file)

          if media_file.instance_of?(Hash) && media_file.size > 0

            name = media_file[:name]

            type = media_file[:type]

            uri = media_file[:uri]

            if name != nil && type != nil && uri != nil

              base64_uri_array = uri.split(",")

              base64_uri = base64_uri_array[base64_uri_array.length - 1]

              temp_file = Tempfile.new(name)

              temp_file.binmode

              temp_file.write Base64.decode64(base64_uri)

              temp_file.rewind

              name_array = name.split(".")

              extension = name_array[name_array.length - 1].downcase

              if media_file_valid_extensions.include?(extension)

                media_file = ActionDispatch::Http::UploadedFile.new({
                                                                        tempfile: temp_file,
                                                                        type: type,
                                                                        filename: name
                                                                    })

                post.media_type = get_media_file_type(extension)


              else

                @success = false
                @message = 'Upload a media file with appropriate extension and try again'
                return

              end



            else

              @success = false
              @message = 'Invalid media file'
              return

            end



          else


            @success = false
            @message = 'Invalid media file'
            return


          end



        else


          if !media_file.is_a?(ActionDispatch::Http::UploadedFile) || !is_media_file_valid?(media_file)


            @success = false
            @message = 'Upload a media file with appropriate extension and try again'
            return


          else

            filename = media_file.original_filename.split(".")

            extension = filename[filename.length - 1].downcase

            post.media_type = get_media_file_type(extension)



          end



        end


        media_type = post.media_type_before_type_cast


        if media_type == 0

          post.image_file = media_file

          if post.save!

            @success = true


            if post.is_story

              Delayed::Job.enqueue(StoryJob.new(post.id, current_user.id), queue: 'delete_story_post_queue', priority: 0, run_at: 24.hours.from_now)

            end


            PostBroadcastJob.perform_later(current_user.id)

            return


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


          post.video_file = media_file



          if post.save!

            @success = true


            if post.is_story

              Delayed::Job.enqueue(StoryJob.new(post.id, current_user.id), queue: 'delete_story_post_queue', priority: 0, run_at: 24.hours.from_now)

            end

            File.delete(thumbnail_path) if File.exist?(thumbnail_path)

            PostBroadcastJob.perform_later(current_user.id)

            return


          else

            @success = false

            @message = "Error creating post"

            return

          end

        end





      else

        @success = false
        @message = 'Error creating post'


      end



    end






  end



  private


  def media_file_valid_extensions
    %w(png jpeg jpg gif flv avi mp4 wmv mov mkv 3gp)
  end

  def is_media_file_valid?(media_file)

    filename = media_file.original_filename.split(".")

    extension = filename[filename.length - 1].downcase

    media_file_valid_extensions.include?(extension)

  end



  def get_media_file_type(extension)

    image_extensions = %w(png jpeg jpg gif)

    video_extensions = %w(flv avi mp4 wmv mov mkv 3gp)

    if image_extensions.include?(extension)
      0
    elsif video_extensions.include?(extension)
      1
    end


  end

end
