class PostCase < ApplicationRecord

  has_many :post_reports, :dependent => :delete_all

  enum review_status: { unreviewed: 0, reviewed: 1 }

  belongs_to :user, foreign_key: 'post_author_id'

  def post_author_username

    self.user.username

  end

  def get_post_complaints

    # Show copyright violation reports first

    post_reports = self.post_reports.where(report_type: 0) + self.post_reports.where.not(report_type: 0)

    post_complaints = []

    post_reports.each do |post_report|

      post_complaints.push({
                               username: post_report.get_username,
                               profile_id: post_report.get_user_profile.id,
                               report_type: post_report.report_type,
                               additional_info: post_report.additional_information
                           })

    end

    post_complaints



  end


  def get_admins_reviewed

    admins_reviewed = self.admins_reviewed.map &:to_i

    admins_reviewed.each do |admin_id|

      admin = Admin.find_by(id: admin_id)

      if admin.nil?

        admins_reviewed.delete(admin_id)

      end

    end


    self.update!(admins_reviewed: admins_reviewed)

    admins_reviewed


  end

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
