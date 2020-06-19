class PhoneNumber < ApplicationRecord

  validates_uniqueness_of :number

  def can_request_sms?
    current_time = (DateTime.now.utc).to_datetime
    current_time >= self.next_request_at
  end

end
