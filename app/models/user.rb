# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  before_destroy :destroy_user_attributes
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable
  include DeviseTokenAuth::Concerns::User

  validates :username, presence: :true, uniqueness: { case_sensitive: false }

  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true

  enum user_type: { customer_user: 0, store_user: 1 }

  has_one :profile

  after_create :create_profile

  private

  def create_profile

    Profile.create!(user_id: self.id)

  end

  def destroy_user_attributes

    if self.customer_user?
      CustomerUser.find_by(customer_id: self.id).destroy
    elsif self.store_user?
      StoreUser.find_by(store_id: self.id).destroy
    end

  end

end
