class Follow < ApplicationRecord

  belongs_to :follower, class_name: 'User'
  belongs_to :followed, class_name: 'User'
  validates_presence_of :follower_id, :followed_id

  enum status: { inactive: 0, active: 1 }

end
