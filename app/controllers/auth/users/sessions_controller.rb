module Auth

  module Users

    class SessionsController < ::DeviseTokenAuth::SessionsController
      # Prevent session parameter from being passed
      # Unpermitted parameter: session
      wrap_parameters format: []


      def destroy

        # remove auth instance variables so that after_action does not run

        user = remove_instance_variable(:@resource) if @resource

        client = @token.client if @token.client

        @token.clear!

        if user && client && user.tokens[client]

          user.update!(push_token: '')

          user.tokens.delete(client)

          user.save!

          yield user if block_given?

          render_destroy_success

        else

          render_destroy_error

        end

      end

      protected



      def render_create_success

        cookies.encrypted[:user_id] = current_user.id
        render json: {
            data: resource_data(resource_json: @resource.token_validation_response)
        }

      end

    end

  end

end
