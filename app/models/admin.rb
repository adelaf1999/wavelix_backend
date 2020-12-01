# frozen_string_literal: true

class Admin < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  devise :database_authenticatable, :rememberable, :trackable, :validatable, :lockable

  include DeviseTokenAuth::Concerns::User

  mount_uploader :profile_photo, ImageUploader

  petergate(roles: [:root_admin, :profile_manager, :order_manager, :account_manager, :employee_manager], multiple: true)

  before_create :setup_verification_code

  private

  def setup_verification_code

    self.renew_verification_code_at = DateTime.now.utc + 10.minutes

    self.verification_code = rand.to_s[2..7]

  end




end
