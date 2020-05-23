class CustomerUser < ApplicationRecord

    belongs_to :customer, touch: true
    serialize :home_address, Hash
    has_many :orders
    has_one :driver, dependent: :destroy
    has_one :cart, dependent: :destroy
    after_create :create_cart


    private

    def create_cart
        Cart.create!(customer_user_id: self.id)
    end



end
