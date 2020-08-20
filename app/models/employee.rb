class Employee < ApplicationRecord

  before_validation :set_uid, on: :create

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable,  authentication_keys: [:username]

  include DeviseTokenAuth::Concerns::User

  validates_uniqueness_of :username

  belongs_to :store_user

  enum status: { inactive: 0, active: 1 }


  private

  def set_uid
    self.uid = self.username
  end

end
