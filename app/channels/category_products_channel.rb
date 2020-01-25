class CategoryProductsChannel < ApplicationCable::Channel

  def subscribed

    if current_user.blank? || category.blank?
      reject
    else
      stream_from "category_#{category.id}_products_user_#{current_user.id}"
    end


  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

end