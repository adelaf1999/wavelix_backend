class CustomerUser < ApplicationRecord
    belongs_to :customer, touch: true
    serialize :home_address, Hash
end
