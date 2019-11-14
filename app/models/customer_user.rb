class CustomerUser < ApplicationRecord
    belongs_to :customer, touch: true
end
