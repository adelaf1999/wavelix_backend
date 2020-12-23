class Profile < ApplicationRecord

  validates_presence_of :user_id

  enum privacy: { public_account: 0, private_account: 1 }

  enum status: { unblocked: 0, blocked: 1 }

  mount_uploader :profile_picture, ImageUploader

  has_many :posts, dependent: :destroy

  belongs_to :user

end
