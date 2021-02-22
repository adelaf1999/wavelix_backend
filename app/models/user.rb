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

  has_one :profile, dependent: :destroy

  after_create :create_profile

  has_many :following_relationships, class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy

  has_many :follower_relationships, class_name: 'Follow', foreign_key: 'followed_id', dependent: :destroy

  has_many :following, through: :following_relationships, source: :followed

  has_many :followers, through: :follower_relationships, source: :follower


  has_many :comments, foreign_key: 'author_id'

  has_many :likes, foreign_key: 'liker_id'

  has_many :post_cases, foreign_key: 'post_author_id'

  after_commit :update_post_cases, on: :update, if: proc { |object| object.previous_changes.include?('username') }


  def active_followers

    self.followers.merge(self.follower_relationships.where(status: 1))

  end


  def active_followings

    self.following.merge(self.following_relationships.where(status: 1))

  end

  def accept_follow_request(other)

    follower_relationship = Follow.find_by(follower_id: other.id)

    if follower_relationship != nil && follower_relationship.inactive?

      follower_relationship.active!

      true

    else

      false

    end


  end

  def follow_requests

    self.follower_relationships.where(status: 0)

  end

  def follow(other)

    # To follow a store it must be verified
    # To follow a person their account must be public
    # A person that wants to follow must verify their phone number
    # Can only follow another person if their phone number is verified as well
    # If their account is not public create a request to follow
    # A store cannot follow anyone if its not verified

    if other.id != self.id && !following?(other)

      if self.store_user?

        this_store_user = StoreUser.find_by(store_id: self.id)

        if this_store_user.verified?

          create_following_relationship(other)

        else

          false

        end

      else

        this_customer_user = CustomerUser.find_by(customer_id: self.id)

        if this_customer_user.phone_number_verified?

          create_following_relationship(other)

        else

          false

        end



      end


    else

      false


    end



  end

  def unfollow(other)

    other_following_relationship = following_relationships.find_by(followed_id: other.id)

    if other_following_relationship != nil

      other_following_relationship.destroy

      true

    else

      false

    end

  end

  def following?(other)
    # can be active or inactive
    following.include?(other)
  end


  private

  def update_post_cases

    self.post_cases.each do |post_case|

      post_case.update!(post_author_username: self.username)

    end

  end


  def create_following_relationship(other)

    if other.store_user?

      other_store = StoreUser.find_by(store_id: other.id)

      if other_store.verified?
        following_relationships.create!(followed_id: other.id)
        true
      else
        false
      end

    else

      other_customer = CustomerUser.find_by(customer_id: other.id)

      if other_customer.phone_number_verified?

        other_profile  = other.profile

        if other_profile.public_account?
          following_relationships.create!(followed_id: other.id)
          true
        else
          following_relationships.create!(followed_id: other.id, status: 0)
          true
        end

      else

        false

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
