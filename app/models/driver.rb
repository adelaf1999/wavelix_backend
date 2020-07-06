class Driver < ApplicationRecord

  acts_as_mappable :distance_field_name => :distance,
                   :lat_column_name => :latitude,
                   :lng_column_name => :longitude

  belongs_to :customer_user, touch: true

  has_many :orders

  enum status: { offline: 0, online: 1 }

  mount_uploader :profile_picture, ImageUploader

  mount_uploaders :driver_license_pictures, ImageUploader

  mount_uploaders :national_id_pictures, ImageUploader

  mount_uploaders :vehicle_registration_document_pictures, ImageUploader

  serialize :driver_license_pictures, Array

  serialize :national_id_pictures, Array

  serialize :vehicle_registration_document_pictures, Array

end
