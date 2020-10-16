module Auth

    module Users

        class UnlocksController < DeviseTokenAuth::ApplicationController
            skip_after_action :update_auth_header, only: [:create, :show]
        
            # this action is responsible for generating unlock tokens and
            # sending emails
            def create
              return render_create_error_missing_email unless resource_params[:email]
        
              @email = get_case_insensitive_field_from_resource_params(:email)
              @resource = find_resource(:email, @email)
        
              if @resource
                yield @resource if block_given?
        
                @resource.delay.send_unlock_instructions(
                  email: @email,
                  provider: 'email',
                  client_config: params[:config_name]
                )
        
                if @resource.errors.empty?
                  return render_create_success
                else
                  render_create_error @resource.errors
                end
              else
                render_not_found_error
              end
            end
        
            def show
              @resource = resource_class.unlock_access_by_token(params[:unlock_token])
        
              if @resource.persisted?
                token = @resource.create_token
                @resource.save!
                yield @resource if block_given?


                redirect_to_web

              else
                # render_show_error
                if @resource.locked_at? == false
                    # already unlocked 

                    redirect_to_web

                else
                   # redirect to 404 not found page or something went wrong page in the website
                end

              end
            end
        
            private


            def redirect_to_web

              if Rails.env.production?
                redirect_to(ENV.fetch("PRODUCTION_WEBSITE_URL"))
              else
                redirect_to(ENV.fetch("DEVELOPMENT_WEBSITE_URL"))
              end

            end


            def after_unlock_path_for(resource)
              #TODO: This should probably be a configuration option at the very least.
              '/'
            end
        
            def render_create_error_missing_email
              render_error(401, I18n.t('devise_token_auth.unlocks.missing_email'))
            end
        
            def render_create_success
              render json: {
                success: true,
                message: I18n.t('devise_token_auth.unlocks.sended', email: @email)
              }
            end
        
            def render_create_error(errors)
              render json: {
                success: false,
                errors: errors
              }, status: 400
            end
        
            def render_show_error
              raise ActionController::RoutingError, 'Not Found'
            end
        
            def render_not_found_error
              render_error(404, I18n.t('devise_token_auth.unlocks.user_not_found', email: @email))
            end
        
            def resource_params
              params.permit(:email, :unlock_token, :config)
            end
          end

    end

end