class CustomerUser < ApplicationRecord
    belongs_to :customer, touch: true
    serialize :home_address, Hash
    has_many :orders
    has_one :driver, dependent: :destroy
end
