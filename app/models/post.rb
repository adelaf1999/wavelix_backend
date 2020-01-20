class Post < ApplicationRecord

  belongs_to :profile

  validates_presence_of :profile_id, :media_type, :media_file

  enum media_type: { image: 0, video: 1 }

  mount_uploader :media_file, MediaUploader

end
