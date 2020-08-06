class EarningAccount < ApplicationRecord

  validates_uniqueness_of :currency

end
