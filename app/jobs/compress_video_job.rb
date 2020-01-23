class CompressVideoJob < Struct.new(:post_id, :local_video_file_id, :user_id)

  def perform

    post = Post.find_by(id: post_id)

    local_video_file = LocalVideo.find_by(id: local_video_file_id)

    post.video_file = ActionDispatch::Http::UploadedFile.new({
                                                                 filename: local_video_file.video.file.filename,
                                                                 content_type: local_video_file.video.content_type,
                                                                 tempfile: local_video_file.video.file
                                                             })



    if post.delay.save!

      post.complete!

      local_video_file.destroy

      PostBroadcastJob.perform_later(user_id)


    end


  end

end