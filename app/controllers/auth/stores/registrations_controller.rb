module Auth

    module Stores

        class RegistrationsController < DeviseTokenAuth::ApplicationController
            before_action :validate_sign_up_params, only: :create
            skip_after_action :update_auth_header, only: [:create]
            
            
        
            def create
              build_resource
        
              unless @resource.present?
                raise DeviseTokenAuth::Errors::NoResourceDefinedError,
                      "#{self.class.name} #build_resource does not define @resource,"\
                      ' execution stopped.'
              end
        
              # give redirect value from params priority
              # @redirect_url = params.fetch(
              #   :confirm_success_url,
              #   DeviseTokenAuth.default_confirm_success_url
              # )

              
              # The redirect url is the page the user will be redirected to upon
              # successful email confirmation

              @redirect_url = "http://192.168.1.103:19006"

             
        
              # success redirect url is required
              if confirmable_enabled? && !@redirect_url
                return render_create_error_missing_confirm_success_url
              end
        
              # if whitelist is set, validate redirect_url against whitelist
              return render_create_error_redirect_url_not_allowed if blacklisted_redirect_url?(@redirect_url)
        
              # override email confirmation, must be sent manually from ctrl
              callback_name = defined?(ActiveRecord) && resource_class < ActiveRecord::Base ? :commit : :create
              resource_class.set_callback(callback_name, :after, :send_on_create_confirmation_instructions)
              resource_class.skip_callback(callback_name, :after, :send_on_create_confirmation_instructions)
        
              if @resource.respond_to? :skip_confirmation_notification!
                # Fix duplicate e-mails by disabling Devise confirmation e-mail
                @resource.skip_confirmation_notification!
              end
        
              if @resource.save
                yield @resource if block_given?
        
                unless @resource.confirmed?
                  # user will require email authentication
                  @resource.send_confirmation_instructions({
                    client_config: params[:config_name],
                    redirect_url: @redirect_url
                  })
                end
        
                if active_for_authentication?
                  # email auth has been bypassed, authenticate user
                  @token = @resource.create_token
                  @resource.save!
                  update_auth_header
                end
        
                render_create_success
              else
                clean_up_passwords @resource
                render_create_error
              end

            end

        
        
            def sign_up_params
              # you will get unpermitted parameter for customer_user_attributes thats normal behavior
               params.permit(*params_for_resource(:sign_up))
            end
        
            def store_user_params
                params.permit(:store_owner_full_name, :store_owner_work_number, :store_name, :store_address, :store_number, :store_country, :store_business_license)
            end

            def validate_store_user_params(store_params)

                 # returns true if valid
                 # return false if invalid or missing params

                 valid = true

                 req_params = [:store_owner_full_name, :store_owner_work_number, :store_name, :store_address, :store_number, :store_country, :store_business_license]

                 req_params.each do |p|
                    if store_params[p] == nil
                      valid = false
                      break
                    end
                end

                if valid

                    # no parameters are missings
                    
                    store_owner_full_name = store_params[:store_owner_full_name]
                    store_owner_work_number = store_params[:store_owner_work_number]
                    store_name = store_params[:store_name]
                    store_address = store_params[:store_address]
                    store_number = store_params[:store_number]
                    store_country = store_params[:store_country]
                    store_business_license = store_params[:store_business_license]

                    if store_owner_full_name.length == 0
                        valid = false
                    end

                    if valid && store_owner_work_number.length == 0
                        valid = false
                    end

                    if valid && store_name.length == 0
                        valid = false
                    end

                    if valid && store_address.length == 0
                        valid = false
                    end

                    if valid && store_number.length == 0
                        valid = false
                    end

                    if valid && !is_country_valid?(store_country)
                        valid = false
                    end

                    if valid && !is_business_license_valid?(store_business_license)
                        valid = false
                    end

                    

                end

                valid

            end

           
        
            protected

            def is_business_license_valid?(business_license)

                filename = business_license.original_filename.split(".")
                extension = filename[filename.length - 1]
                valid_extensions = ["png" , "jpeg", "jpg", "pdf" ,"doc" , "docx", "odt"]

                valid_extensions.include?(extension)

            end

            def is_birthdate_valid?(date)

              valid = true
              

              begin
                
           
                t_date = Time.strptime(date,'%m-%d-%Y')
           
                # check if parsed date is same as input date
                if t_date.strftime('%m-%d-%Y') != date
                   valid = false
                end
           
             rescue ArgumentError => e
                valid = false
             end

             valid
              
              
  
            end
  
            def is_country_valid?(country_code)
              
              c = ISO3166::Country.new(country_code)
  
              if c == nil || country_code == "IL"
                false
              else
                true
              end
  
            end
        
            def build_resource
              @resource            = resource_class.new(sign_up_params)
              @resource.provider   = provider
        
              # honor devise configuration for case_insensitive_keys
              if resource_class.case_insensitive_keys.include?(:email)
                @resource.email = sign_up_params[:email].try(:downcase)
              else
                @resource.email = sign_up_params[:email]
              end

              # check store user params


             store_attributes = store_user_params

              if validate_store_user_params(store_attributes)
                @resource.store_user = StoreUser.new(store_attributes)
              end



            end
        
            def render_create_error_missing_confirm_success_url
              response = {
                status: 'error',
                data:   resource_data
              }
              message = I18n.t('devise_token_auth.registrations.missing_confirm_success_url')
              render_error(422, message, response)
            end
        
            def render_create_error_redirect_url_not_allowed
              response = {
                status: 'error',
                data:   resource_data
              }
              message = I18n.t('devise_token_auth.registrations.redirect_url_not_allowed', redirect_url: @redirect_url)
              render_error(422, message, response)
            end
        
            def render_create_success
              render json: {
                status: 'success',
                data:   resource_data
              }
            end
        
            def render_create_error
              render json: {
                status: 'error',
                data:   resource_data,
                errors: resource_errors
              }, status: 422
            end
        
        
            private
        
        
            def validate_sign_up_params
              validate_post_data sign_up_params, I18n.t('errors.messages.validate_sign_up_params')
            end
        
            def validate_post_data which, message
              render_error(:unprocessable_entity, message, status: 'error') if which.empty?
            end
        
            def active_for_authentication?
              !@resource.respond_to?(:active_for_authentication?) || @resource.active_for_authentication?
            end
          end

    end

end