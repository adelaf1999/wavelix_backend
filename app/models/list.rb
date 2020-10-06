class List < ApplicationRecord

  has_many :list_products, :dependent => :delete_all

  belongs_to :customer_user

  enum privacy: { public_list: 0, private_list: 1 }

end
