class NotificationsController < ApplicationController

  before_action :deny_to_visitors


  def set_push_token

    push_token = params[:push_token]

    if !push_token.nil?

      # When employee or user signs in set push token to ExponentToken[xxxx]

      # When they logout this function is called with empty string to clear it

      # So that multiple users using same device dont receive each others notifications

      @success = true

      if user_signed_in?

        current_user.update!(push_token: push_token)

      else

        current_employee.update!(push_token: push_token)

      end


    else

      @success = false

    end

  end


  private

  def deny_to_visitors

    head :unauthorized unless user_signed_in? or employee_signed_in?

  end


end
