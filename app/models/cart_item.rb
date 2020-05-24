class CartItem < ApplicationRecord


  belongs_to :cart_bundle

  serialize :product_options, Hash



end
