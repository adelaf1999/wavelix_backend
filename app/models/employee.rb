class Employee < ApplicationRecord

  petergate(roles: [:product_manager, :order_manager], multiple: true )

  before_validation :set_uid, on: :create

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable,  authentication_keys: [:username]

  include DeviseTokenAuth::Concerns::User

  validates :username, presence: :true, uniqueness: { case_sensitive: false }

  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true


  belongs_to :store_user

  enum status: { inactive: 0, active: 1 }

 

  def get_store_currency

    self.store_user.currency

  end



  private

  def set_uid
    self.uid = self.username
  end

end
