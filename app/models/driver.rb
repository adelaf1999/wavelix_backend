class Driver < ApplicationRecord

  belongs_to :customer_user, touch: true
  serialize :current_location, Hash
  has_many :orders
  enum status: { offline: 0, online: 1 }



end
