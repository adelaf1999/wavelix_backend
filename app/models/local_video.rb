class LocalVideo < ApplicationRecord

  validates_presence_of :video
  mount_uploader :video, LocalVideoUploader

end
