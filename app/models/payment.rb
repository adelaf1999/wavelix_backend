class Payment < ApplicationRecord

  belongs_to :store_user, optional: true

  belongs_to :driver, optional: true

end
