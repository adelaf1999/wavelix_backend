class CartBundle < ApplicationRecord

  belongs_to :cart

  has_many :cart_items, :dependent => :delete_all

  serialize :delivery_location, Hash

  enum order_type: { standard: 0, exclusive: 1 }

end
