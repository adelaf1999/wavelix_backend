# frozen_string_literal: true

class Admin < ActiveRecord::Base

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable

  devise :database_authenticatable, :rememberable, :trackable, :timeoutable, :validatable, :lockable

  include DeviseTokenAuth::Concerns::User

  mount_uploader :profile_photo, ImageUploader

  petergate(roles: [:root_admin, :profile_manager, :order_manager, :account_manager, :employee_manager], multiple: true)




end
