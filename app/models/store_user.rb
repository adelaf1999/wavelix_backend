class StoreUser < ApplicationRecord

    belongs_to :store, touch: true
    mount_uploader :store_business_license, BusinessLicenseUploader
    serialize :store_address, Hash
    has_many :categories

    enum status: {unverified: 0, verified: 1}

end
