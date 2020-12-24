class Profile < ApplicationRecord

  validates_presence_of :user_id

  enum privacy: { public_account: 0, private_account: 1 }

  enum status: { unblocked: 0, blocked: 1 }

  mount_uploader :profile_picture, ImageUploader

  has_many :posts, dependent: :destroy

  belongs_to :user

  has_many :block_requests

  def get_user_type

    self.user.user_type

  end


  def get_email

    self.user.email

  end


  def get_username

    self.user.username

  end

  def get_admins_requested_block

    admins_requested_block = self.admins_requested_block.map &:to_i

    admins_requested_block.each do |admin_id|

      admin = Admin.find_by(id: admin_id)

      if admin.nil?

        admins_requested_block.delete(admin_id)

      end

    end

    self.update!(admins_requested_block: admins_requested_block)

    admins_requested_block

  end


end
