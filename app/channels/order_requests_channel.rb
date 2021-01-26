class OrderRequestsChannel  < ApplicationCable::Channel


  def set_driver_offline(driver)

    if driver.online?


      driver.offline!


      # If driver has a pending order request add him to drivers rejected and find a new driver

      order = Order.find_by(driver_id: nil, status: 1, prospective_driver_id: driver.id)

      if order != nil

        drivers_rejected = order.get_drivers_rejected

        if !drivers_rejected.include?(driver.id)

          drivers_rejected.push(driver.id)

          order.update!(drivers_rejected: drivers_rejected)

          FindNewDriverJob.perform_later(order.id)

        end

      end

    end



  end


  def subscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    user = User.find_by_uid(uid)

    if user != nil &&  user.valid_token?(access_token, client)

      if user.customer_user?

        customer_user = CustomerUser.find_by(customer_id: user.id)

        driver = customer_user.driver

        if driver != nil

          stream_from "order_requests_channel_#{customer_user.id}"

        else

          reject

        end

      else

        reject

      end

    else

      reject

    end


  end


  def unsubscribed

    access_token = params[:access_token]

    client = params[:client]

    uid = params[:uid]

    user = User.find_by_uid(uid)

    if user != nil &&  user.valid_token?(access_token, client)

      if user.customer_user?

        customer_user = CustomerUser.find_by(customer_id: user.id)

        driver = customer_user.driver

        if driver != nil

          set_driver_offline(driver)

        end


      end


    end


  end


end