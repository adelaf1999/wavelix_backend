module PostCaseHelper

  def destroy_post_case(post)

    post_case = post.post_case

    if post_case != nil

      if post_case.unreviewed?

        ActionCable.server.broadcast 'post_cases_channel', {
            post_case_deleted: true,
            id: post_case.id
        }

        ActionCable.server.broadcast "view_post_case_channel_#{post_case.id}", {
            post_case_deleted: true
        }

        post_case.destroy!

      end

    end

  end

end