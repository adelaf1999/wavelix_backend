module  Auth
    
    module Customers

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

              @redirect_url = Rails.env.production? ?  ENV.fetch("PRODUCTION_WEBSITE_URL")  : ENV.fetch("DEVELOPMENT_WEBSITE_URL")

             
        
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
        

            def customer_user_params
              params.permit(:full_name, :date_of_birth, :gender, :country_of_residence, :home_address, :building_name, :apartment_floor)
            end

            def validate_customer_user_params

              valid = true

              req_params = [:full_name, :date_of_birth, :country_of_residence, :gender, :home_address ]

              customer_params = customer_user_params

              req_params.each do |p|
                  if customer_params[p] == nil
                    valid = false
                    break
                  end
              end

              
              if valid

                # no parameters are missings (except maybe optional)

                full_name = customer_params[:full_name]
                date_of_birth = customer_params[:date_of_birth]
                gender = customer_params[:gender].downcase
                country_code = customer_params[:country_of_residence]
                home_address = eval(customer_params[:home_address])
                latitude = home_address[:latitude]
                longitude = home_address[:longitude]
                c = ISO3166::Country.new(country_code)


                if full_name.length == 0
                  valid = false
                end

                if valid && !is_birthdate_valid?(date_of_birth)
                  valid = false
                end

              

                if valid && gender != "male" && gender != "female" && gender != "other"
                  valid = false
                end

                
                if valid && (c == nil || country_code == "IL")
                  valid = false
                end

                if valid && latitude != nil
                  latitude = latitude.to_s
                else
                  valid = false
                end

                if valid && longitude != nil
                  longitude = longitude.to_s
                else
                  valid = false
                end

                if valid && ( !is_number?(latitude) || !is_number?(longitude) )
                    valid = false
                end

                building_name = customer_params[:building_name]
                apartment_floor = customer_params[:apartment_floor]

                

                if valid

                  @resource.customer_user = CustomerUser.new(
                    full_name: full_name,
                    date_of_birth: date_of_birth,
                    gender: gender,
                    country_of_residence: c.name,
                    home_address: home_address
                  )

                  if building_name != nil 
                    @resource.customer_user.building_name = building_name
                  end

                  if apartment_floor != nil && is_number?(apartment_floor)
                    @resource.customer_user.apartment_floor = apartment_floor
                  end

                end

              end

        

            end
        
            protected

            def is_number?(arg)
              if /^\d+([.]\d+)?$/.match(arg) == nil
                false
              else
                true
              end
            end

            def is_birthdate_valid?(date)

              valid = true
              

              begin
                

                t_date = Time.strptime(date,'%Y-%m-%d')


                # t_date_values = t_date.strftime('%Y-%m-%d').split("-")

                date_values = date.split("-")

                if t_date.year != date_values[0].to_i || t_date.month != date_values[1].to_i || t_date.day != date_values[2].to_i
                  valid = false
                end
                
           
             rescue ArgumentError => e
                valid = false
             end

             valid
              
              
  
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

              # check customer user params
              validate_customer_user_params



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