module Auth

  module Stores

    class RegistrationsController < DeviseTokenAuth::ApplicationController
      include CountriesHelper
      include MoneyHelper
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
            @resource.delay.send_confirmation_instructions({
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

          ActionCable.server.broadcast 'store_accounts_channel', {new_store_registered: true}


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
        params.permit(:store_owner_full_name, :store_owner_work_number, :store_name, :store_address, :store_number,  :store_business_license, :currency, :schedule, :handles_delivery, :has_sensitive_products)
      end

      def validate_store_user_params


        valid = true

        req_params = [:store_owner_full_name, :store_owner_work_number, :store_name, :store_address, :store_number, :store_business_license, :currency, :schedule, :handles_delivery, :has_sensitive_products]


        store_params = store_user_params

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
          store_number = store_params[:store_number]
          store_business_license = store_params[:store_business_license]
          currency = store_params[:currency]
          handles_delivery = eval(store_params[:handles_delivery])
          has_sensitive_products = eval(store_params[:has_sensitive_products])


          begin

            schedule = eval(store_params[:schedule])

          rescue SyntaxError, NameError

            valid = false

          end

          store_address = eval(store_params[:store_address])
          latitude = store_address[:latitude]
          longitude = store_address[:longitude]


          if valid &&  ( !is_boolean?(handles_delivery) || !is_boolean?(has_sensitive_products) )

            valid = false

          end



          if valid && store_owner_full_name.length == 0
            valid = false
          end

          if valid && store_owner_work_number.length == 0
            valid = false
          end

          if valid && store_name.length == 0
            valid = false
          end


          if valid && store_number.length == 0
            valid = false
          end

          # if valid && (c == nil || store_country_code == "IL")
          #   valid = false
          # end

          if valid && !is_business_license_valid?(store_business_license)
            valid = false
          end

          if valid && !is_currency_valid?(currency)
            valid = false
          end


          if valid && latitude != nil
            latitude = latitude.to_d
          else
            valid = false
          end

          if valid && longitude != nil
            longitude = longitude.to_d
          else
            valid = false
          end

          if valid && ( !is_number?(latitude) || !is_number?(longitude) || store_address.size != 2 )
            valid = false
          end

          if valid && schedule.instance_of?(Hash)

            if schedule.size == 7

              days = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

              schedule.each do |day, values|

                if !days.include?(day)

                  valid = false

                else

                  closed = values[:closed]

                  open_at = values[:open_at]

                  close_at = values[:close_at]

                  if closed == nil

                    valid = false

                  else

                    if !closed

                      if open_at == nil || close_at == nil

                        valid = false

                      else

                        open_at_array = open_at.split(':')

                        close_at_array = close_at.split(':')

                        if open_at_array.size != 3 || close_at_array.size != 3

                          valid = false

                        else


                          if !is_time_valid?(open_at_array) || !is_time_valid?(close_at_array)

                            valid = false

                          elsif open_at == close_at

                            valid = false

                          end


                        end

                      end



                    end





                  end


                end

              end


              if valid

                for i in 0..6

                  current_day_values = schedule[days[i]]

                  current_day_closed = current_day_values[:closed]

                  if !current_day_closed

                    current_day_open_at = current_day_values[:open_at]

                    current_day_close_at = current_day_values[:close_at]

                    if current_day_open_at > current_day_close_at

                      if i === 6

                        monday_values = schedule[:monday]

                        monday_closed = monday_values[:closed]

                        if !monday_closed

                          monday_open_at = monday_values[:open_at]

                          if current_day_close_at > monday_open_at

                            valid = false

                            break

                          end

                        end


                      else

                        next_day_values = schedule[days[i+ 1]]

                        next_day_closed = next_day_values[:closed]

                        if !next_day_closed

                          next_day_open_at = next_day_values[:open_at]

                          if current_day_close_at > next_day_open_at

                            valid = false

                            break

                          end

                        end

                      end

                    end

                  end

                end

              end



            else

              valid = false

            end

          else

            valid = false

          end


          if valid

            store_address[:latitude] = latitude
            store_address[:longitude] = longitude

            results = Geocoder.search([latitude, longitude])

            country_code = results.first.country_code

            if !is_country_blocked?(country_code)


              @resource.store_user = StoreUser.new(
                  store_owner_full_name: store_owner_full_name,
                  store_owner_work_number: store_owner_work_number,
                  store_name: store_name,
                  store_address: store_address,
                  store_number: store_number,
                  store_country: country_code,
                  store_business_license: store_business_license,
                  currency: currency,
                  has_sensitive_products: has_sensitive_products,
                  handles_delivery: handles_delivery
              )


              @resource.store_user.schedule = Schedule.new


              days = {
                  :monday => Day.new(week_day: 'monday'),
                  :tuesday => Day.new(week_day: 'tuesday'),
                  :wednesday => Day.new(week_day: 'wednesday'),
                  :thursday => Day.new(week_day: 'thursday'),
                  :friday => Day.new(week_day: 'friday'),
                  :saturday => Day.new(week_day: 'saturday'),
                  :sunday => Day.new(week_day: 'sunday')
              }


              week_days = schedule.keys

              for i in 0..6

                day = days[week_days[i]]

                current_day_values = schedule[week_days[i]]

                current_day_closed = current_day_values[:closed]

                previous_day_values = i == 0 ? schedule[week_days[6]]  : schedule[week_days[i - 1]]

                previous_day_closed = previous_day_values[:closed]

                if previous_day_closed

                  if current_day_closed

                    day.closed = true

                    days[week_days[i]] = day

                  else

                    current_day_open_at = current_day_values[:open_at]

                    current_day_close_at = current_day_values[:close_at]

                    if current_day_open_at > current_day_close_at

                      day.open_at_1 = current_day_open_at

                      day.close_at_1 = '23:59:59'

                      days[week_days[i]] = day


                    else

                      day.open_at_1 = current_day_open_at

                      day.close_at_1 = current_day_close_at

                      days[week_days[i]] = day


                    end

                  end

                else

                  previous_day_open_at = previous_day_values[:open_at]

                  previous_day_close_at = previous_day_values[:close_at]

                  if previous_day_open_at > previous_day_close_at

                    day.open_at_1 = '00:00:00'

                    day.close_at_1 = previous_day_close_at

                    if current_day_closed

                      days[week_days[i]] = day

                    else

                      current_day_open_at = current_day_values[:open_at]

                      current_day_close_at = current_day_values[:close_at]

                      if current_day_open_at > current_day_close_at

                        day.open_at_2 = current_day_open_at

                        day.close_at_2 = '23:59:59'

                        days[week_days[i]] = day

                      else

                        day.open_at_2 = current_day_open_at

                        day.close_at_2 = current_day_close_at

                        days[week_days[i]] = day

                      end


                    end

                  else


                    if current_day_closed

                      day.closed = true

                      days[week_days[i]] = day

                    else

                      current_day_open_at = current_day_values[:open_at]

                      current_day_close_at = current_day_values[:close_at]

                      if current_day_open_at > current_day_close_at

                        day.open_at_1 = current_day_open_at

                        day.close_at_1 = '23:59:59'

                        days[week_days[i]] = day


                      else

                        day.open_at_1 = current_day_open_at

                        day.close_at_1 = current_day_close_at

                        days[week_days[i]] = day


                      end


                    end

                  end


                end


              end


              days.values.each do |day|

                @resource.store_user.schedule.days.push(day)

              end



            end


          end




        end



      end



      protected

      def is_boolean?(value)
        [true, false].include? value
      end

      def is_time_valid?(time)

        hours = time[0]

        minutes = time[1]

        seconds = time[2]

        is_hours_valid?(hours) && is_minutes_valid?(minutes) && is_seconds_valid?(seconds)


      end

      def validate_time(time)

        if is_positive_integer?(time)

          time = time.to_i

          time <= 59

        else

          false

        end

      end


      def is_seconds_valid?(seconds)

        validate_time(seconds)

      end

      def is_minutes_valid?(minutes)

        validate_time(minutes)

      end

      def is_hours_valid?(hours)

        if is_positive_integer?(hours)

          hours = hours.to_i

          hours <= 23

        else

          false

        end

      end

      def is_positive_integer?(arg)

        res = /^(?<num>\d+)$/.match(arg)

        if res == nil
          false
        else
          true
        end

      end






      def is_number?(arg)
        arg.is_a?(Numeric)
      end

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

        validate_store_user_params



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