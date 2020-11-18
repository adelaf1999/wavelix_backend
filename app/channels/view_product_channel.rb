class ViewProductChannel < ApplicationCable::Channel

  def start_stream(current_user)

    if current_user.customer_user?

      customer_user  = CustomerUser.find_by(customer_id: current_user.id)

      stream_from "view_product_#{customer_user.id}_channel"
      
    else

      reject


    end

  end


  def subscribed

    if current_user.blank?

      access_token = params[:access_token]

      client = params[:client]

      uid = params[:uid]

      user = User.find_by_uid(uid)

      if user != nil && user.valid_token?(access_token, client)

        start_stream(user)

      else

        reject

      end


    else

      start_stream(current_user)

    end

  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end


end