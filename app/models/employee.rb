class Employee < ApplicationRecord

  petergate(roles: [:product_manager, :order_manager], multiple: true )

  before_validation :set_uid, on: :create

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable,  authentication_keys: [:username]

  include DeviseTokenAuth::Concerns::User

  validates_uniqueness_of :username

  belongs_to :store_user

  enum status: { inactive: 0, active: 1 }

  def roles=(v)

    self[:roles] = v.map(&:to_sym).to_a.select{|r| r.size > 0 && ROLES.include?(r)}

    self.save!

  end


  private

  def set_uid
    self.uid = self.username
  end

end
