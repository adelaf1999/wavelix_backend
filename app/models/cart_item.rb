class CartItem < ApplicationRecord


  belongs_to :cart

  serialize :delivery_location, Hash

  enum order_type: { standard: 0, exclusive: 1 }

  serialize :product_options, Hash



end
