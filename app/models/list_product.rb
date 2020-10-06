class ListProduct < ApplicationRecord

  belongs_to :list

  belongs_to :customer_user

end
