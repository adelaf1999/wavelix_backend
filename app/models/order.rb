class Order < ApplicationRecord

  enum status: {canceled: 0, pending: 1, ongoing: 2, complete: 3}
  enum store_confirmation_status: {store_unconfirmed: 0, store_rejected: 1, store_accepted: 2}
  enum order_type: { standard: 0, exclusive: 1 } # Can be nil if store handles delivery
  serialize :delivery_location, Hash

  belongs_to :store_user
  belongs_to :customer_user

end
