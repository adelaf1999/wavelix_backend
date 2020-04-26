class Post < ApplicationRecord

  belongs_to :profile

  validates_presence_of :profile_id, :media_type

  mount_uploader :image_file, ImageUploader

  mount_uploader :video_file, VideoUploader

  mount_uploader :video_thumbnail, ImageUploader

  enum media_type: { image: 0, video: 1 }

  enum status: { incomplete: 0, complete: 1 }

  has_many :comments

  has_many :likes


end
