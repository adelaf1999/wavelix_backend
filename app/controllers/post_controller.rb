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
          media_type = get_media_file_type(media_file)
          post.media_type = media_type

          caption = params[:caption]

          if caption != nil && caption.length > 0

            post.caption = caption

          end

          if media_type == 0

            # The user will wait till his image is uploaded and encoded

            if post.save!

              post.image_file = media_file

              if post.delay.save!

                post.complete!


                @success = true

                PostBroadcastJob.perform_later(current_user.id)


                return

              end

            else

              @success = false
              @message = "Error creating post"
              return

            end


          else

            if post.save!

              @success = true

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
