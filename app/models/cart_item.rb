class CartItem < ApplicationRecord


  belongs_to :cart

  serialize :product_options, Hash



end
