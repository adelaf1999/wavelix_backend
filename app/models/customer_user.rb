class CustomerUser < ApplicationRecord

    include PaymentsHelper

    include NotificationsHelper

    belongs_to :customer, touch: true

    serialize :home_address, Hash

    has_many :orders

    has_one :driver, dependent: :destroy

    has_one :cart, dependent: :destroy

    has_many :lists, dependent: :destroy

    after_create :create_cart, :save_stripe_customer_token, :create_default_list

    before_destroy :delete_stripe_account


    def push_token

        self.customer.push_token

    end


    def send_notification(message_body, message_title = nil, message_data = nil)


        send_push_notification(self.push_token, message_body, message_title, message_data)

    end

    def phone_number_verified?
        self.phone_number_verified
    end

    def payment_source_setup?

        has_saved_card?(self.stripe_customer_token)

    end

    def setup_payment_source

        create_setup_intent(self.stripe_customer_token)

    end


    private

    def create_default_list

        List.create!(name: 'My Wishlist', privacy: 1, customer_user_id: self.id, is_default: true)

    end

    def create_cart
        Cart.create!(customer_user_id: self.id)
    end


    def save_stripe_customer_token

        name = self.full_name

        email = self.customer.email

        customer_user_id = self.id

        self.stripe_customer_token = create_stripe_customer(name, email, customer_user_id)

        self.save!

    end

    def delete_stripe_account

        destroy_stripe_customer(self.stripe_customer_token)

    end

end
