module Auth

  module Users

    class SessionsController < ::DeviseTokenAuth::SessionsController
      # Prevent session parameter from being passed
      # Unpermitted parameter: session
      wrap_parameters format: []

      def render_create_success

        cookies.encrypted[:user_id] = current_user.id
        render json: {
            data: resource_data(resource_json: @resource.token_validation_response)
        }

      end

    end

  end

end
