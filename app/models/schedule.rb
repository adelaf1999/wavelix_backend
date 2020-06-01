class Schedule < ApplicationRecord

  belongs_to :store_user

  has_many :days, :dependent => :delete_all

end
