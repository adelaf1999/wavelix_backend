class Order < ApplicationRecord

  enum status: {canceled: -1, pending: 0, ongoing: 1, complete: 2}
  serialize :delivery_location, Hash

  belongs_to :driver
  belongs_to :store_user
  belongs_to :customer_user

end
