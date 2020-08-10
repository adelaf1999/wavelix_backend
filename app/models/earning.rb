class Earning < ApplicationRecord

  after_create :increment_earning_account


  private

  def increment_earning_account

    earning_account = EarningAccount.find_by(currency: self.currency)

    if earning_account == nil

      earning_account = EarningAccount.create!(currency: self.currency)

      earning_account.increment!(:balance, self.amount)

    else

      earning_account.increment!(:balance, self.amount)

    end

  end


end
