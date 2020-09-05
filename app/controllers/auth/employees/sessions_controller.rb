module Auth

  module Employees

    class SessionsController < ::DeviseTokenAuth::SessionsController

      # Prevent session parameter from being passed
      # Unpermitted parameter: session
      wrap_parameters format: []

      def create

        # Check
        field = (resource_params.keys.map(&:to_sym) & resource_class.authentication_keys).first

        @resource = nil

        if field

          q_value = get_case_insensitive_field_from_resource_params(field)

          @resource = Employee.find_by(username: q_value)

        end

        if @resource && valid_params?(field, q_value) && (!@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?)
          valid_password = @resource.valid_password?(resource_params[:password])
          if (@resource.respond_to?(:valid_for_authentication?) && !@resource.valid_for_authentication? { valid_password }) || !valid_password
            return render_create_error_bad_credentials
          end
          @token = @resource.create_token
          @resource.save

          sign_in(:user, @resource, store: false, bypass: false)

          yield @resource if block_given?

          render_create_success
        elsif @resource && !(!@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?)
          if @resource.respond_to?(:locked_at) && @resource.locked_at
            render_create_error_account_locked
          else
            render_create_error_not_confirmed
          end
        else
          render_create_error_bad_credentials
        end
      end


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

        cookies.encrypted[:employee_id] = current_employee.id



        render json: {
            data: resource_data(resource_json: @resource.token_validation_response),
            store_currency: current_employee.get_store_currency
        }

      end

    end

  end


end
