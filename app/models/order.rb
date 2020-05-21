class Order < ApplicationRecord

  enum status: {canceled: 0, pending: 1, ongoing: 2, complete: 3}
  enum order_type: { standard: 0, exclusive: 1 }
  serialize :delivery_location, Hash

  belongs_to :store_user
  belongs_to :customer_user

end
