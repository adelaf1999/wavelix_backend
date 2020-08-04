class Order < ApplicationRecord

  include OrderHelper

  enum status: {canceled: 0, pending: 1, ongoing: 2, complete: 3}
  enum store_confirmation_status: {store_unconfirmed: 0, store_rejected: 1, store_accepted: 2}
  enum order_type: { standard: 0, exclusive: 1 } # Can be nil if store handles delivery
  serialize :delivery_location, Hash
  before_create :setup_order
  after_create :send_order

  belongs_to :store_user
  belongs_to :customer_user
  belongs_to :driver, optional: true # can be nil if store handles delivery / no driver selected yet


  private

  def send_order

    send_store_orders(self)

  end



  def setup_order

    if !self.store_handles_delivery

      self.store_fulfilled_order = false

      self.driver_fulfilled_order = false

      self.driver_arrived_to_store = false

      self.driver_arrived_to_delivery_location = false

      self.driver_received_order_code = SecureRandom.hex

      self.driver_fulfilled_order_code = SecureRandom.hex

    end


  end


end
