class Cart < ApplicationRecord

  has_many :cart_bundles

  belongs_to :customer_user, touch: true

end
