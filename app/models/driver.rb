class Driver < ApplicationRecord

  include PaymentsHelper

  acts_as_mappable :distance_field_name => :distance,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  belongs_to :customer_user, touch: true

  has_many :orders

  has_many :payments

  has_many :withdrawals

  has_many :unverified_reasons

  enum status: { offline: 0, online: 1 }

  enum review_status: { unreviewed: 0, reviewed: 1 }

  enum account_status: { unblocked: 0, temporarily_blocked: 1, permanently_blocked: 2 }

  mount_uploader :profile_picture, ImageUploader

  mount_uploaders :driver_license_pictures, ImageUploader

  mount_uploaders :national_id_pictures, ImageUploader

  mount_uploaders :vehicle_registration_document_pictures, ImageUploader

  serialize :driver_license_pictures, Array

  serialize :national_id_pictures, Array

  serialize :vehicle_registration_document_pictures, Array

  after_create :save_stripe_driver_token


  def next_order_resolve_time_limit

    unsuccessful_orders = self.orders.where(
        status: 2,
        store_confirmation_status: 2,
        store_handles_delivery: false,
        store_fulfilled_order: true,
        driver_fulfilled_order: false
    ).where('delivery_time_limit <= ?', DateTime.now.utc)

    if unsuccessful_orders.size > 0

      unsuccessful_orders = unsuccessful_orders.order(resolve_time_limit: :asc)

      unsuccessful_orders.first.resolve_time_limit

    else

      nil

    end


  end

  def payment_source_setup?

    has_saved_card?(self.stripe_customer_token)

  end


  def block_temporarily

    if self.unblocked?

      self.temporarily_blocked!

    end

  end


  def get_email

    self.customer_user.customer.email

  end


  def get_unverified_reasons

    unverified_reasons = []

    self.unverified_reasons.each do |unverified_reason|

      unverified_reasons.push({
                                  admin_name: unverified_reason.admin_name,
                                  reason: unverified_reason.reason
                              })

    end

    unverified_reasons

  end


  def registered_at_utc

    self.created_at.strftime('%Y-%m-%d %H:%M %Z')

  end

  def get_country_name

    ISO3166::Country.new(self.country).name

  end

  def get_phone_number

    self.customer_user.phone_number

  end


  def get_admins_declined

    admins_declined = self.admins_declined.map &:to_i

    admins_declined.each do |admin_id|

      admin = Admin.find_by(id: admin_id)

      if admin.nil?

        admins_declined.delete(admin_id)

      end


    end

    self.update!(admins_declined: admins_declined)

    admins_declined

  end


  def get_admins_reviewing

    admins_reviewing = self.admins_reviewing.map &:to_i

    admins_reviewing.each do |admin_id|

      admin = Admin.find_by(id: admin_id)

      if admin.nil?

        admins_reviewing.delete(admin_id)

      end

    end

    self.update!(admins_reviewing: admins_reviewing)

    admins_reviewing

  end



  def send_notification(message_body, message_title = nil, message_data = nil)


    self.customer_user.send_notification(message_body, message_title, message_data)

  end

  private


  def save_stripe_driver_token

    name = self.name

    driver_id = self.id

    self.stripe_customer_token = create_stripe_token_driver(name, driver_id)

    self.save!

  end

end
