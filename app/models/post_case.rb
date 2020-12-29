class PostCase < ApplicationRecord

  has_many :post_reports

  enum review_status: { unreviewed: 0, reviewed: 1 }

end
