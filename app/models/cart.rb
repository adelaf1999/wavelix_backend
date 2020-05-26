class Cart < ApplicationRecord

  has_many :cart_items, :dependent => :delete_all

  belongs_to :customer_user, touch: true

end
