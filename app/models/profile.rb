class Profile < ApplicationRecord

  validates_presence_of :user_id

  enum privacy: { public_account: 0, private_account: 1 }

  mount_uploader :profile_picture, ImageUploader

  # set limit profile bio to 150 characters

end
