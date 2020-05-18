class Order < ApplicationRecord

  enum status: {canceled: 0, pending: 1, ongoing: 2, complete: 3}
  serialize :delivery_location, Hash

  belongs_to :driver
  belongs_to :store_user
  belongs_to :customer_user

end
