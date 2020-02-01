# frozen_string_literal: true

class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  before_destroy :destroy_user_attributes
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :confirmable, :lockable
  include DeviseTokenAuth::Concerns::User

  validates :username, presence: :true, uniqueness: { case_sensitive: false }

  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true

  enum user_type: { customer_user: 0, store_user: 1 }

  has_one :profile

  after_create :create_profile

  has_many :following_relationships, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :follower_relationships, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy


  has_many :following, through: :following_relationships, source: :followed
  has_many :followers, through: :follower_relationships, source: :follower

  def follow(other)

    # To follow a store it must be verified
    # To follow a person their account must be public
    # If their account is not public create a request to follow
    # A store cannot follow anyone if its not verified

    if other.id != self.id

      if self.store_user?

        this_store_user = StoreUser.find_by(store_id: self.id)

        if this_store_user.verified?

          create_following_relationship(other)

        end

      else

        create_following_relationship(other)

      end


    end



  end

  def unfollow(other)

    other_following_relationship = following_relationships.find_by(followed_id: other.id)

    if other_following_relationship != nil

      other_following_relationship.destroy

    end

  end

  def following?(other)
    following.include?(other)
  end


  private

  def create_following_relationship(other)

    if other.store_user?

      other_store = StoreUser.find_by(store_id: other.id)

      if other_store.verified?
        following_relationships.create!(followed_id: other.id)
      end

    else

      other_profile  = other.profile

      if other_profile.public_account?
        following_relationships.create!(followed_id: other.id)
      else
        following_relationships.create!(followed_id: other.id, status: 0)
      end


    end


  end

  def create_profile

    Profile.create!(user_id: self.id)

  end

  def destroy_user_attributes

    if self.customer_user?
      CustomerUser.find_by(customer_id: self.id).destroy
    elsif self.store_user?
      StoreUser.find_by(store_id: self.id).destroy
    end

  end

end
