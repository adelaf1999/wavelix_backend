class CustomerUser < ApplicationRecord

    include PaymentsHelper

    include NotificationsHelper

    belongs_to :customer, touch: true

    serialize :home_address, Hash

    has_many :orders

    has_many :list_products

    has_one :driver, dependent: :destroy

    has_one :cart, dependent: :destroy

    has_many :lists, dependent: :destroy

    validates :phone_number, uniqueness: true, allow_nil: true

    after_create :create_cart, :save_stripe_customer_token, :create_default_list

    before_destroy :delete_stripe_account

    def get_profile_id

        self.customer.profile.id

    end

    def get_last_sign_in_ip

        self.customer.last_sign_in_ip

    end

    def get_current_sign_in_ip

        self.customer.current_sign_in_ip

    end


    def get_username

        self.customer.username

    end

    def get_country_name

        ISO3166::Country.new(self.country).name

    end


    def get_email

        self.customer.email

    end


    def added_list_product?(product_id)

        self.list_products.find_by(product_id: product_id) != nil

    end


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

        customer_user_id = self.id

        self.stripe_customer_token = create_stripe_token_customer(name, customer_user_id)

        self.save!

    end

    def delete_stripe_account

        destroy_stripe_customer(self.stripe_customer_token)

    end

end
