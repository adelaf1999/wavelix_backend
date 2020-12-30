class PostCase < ApplicationRecord

  has_many :post_reports

  enum review_status: { unreviewed: 0, reviewed: 1 }

  def get_admins_reviewing

    admins_reviewing = self.admins_reviewing.map &:to_i

    admins_reviewing.each do |admin_id|

      admin = Admin.find_by(id: admin_id)

      if admin.nil?

        admins_reviewing.delete(admin_id)

      end

    end

    self.update!(admins_reviewing: admins_reviewing)

    admins_reviewing


  end

end
