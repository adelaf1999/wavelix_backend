class Post < ApplicationRecord

  belongs_to :profile

  validates_presence_of :profile_id, :media_type

  mount_uploader :image_file, ImageUploader

  mount_uploader :video_file, VideoUploader

  mount_uploader :video_thumbnail, ImageUploader

  enum media_type: { image: 0, video: 1 }

  enum status: { incomplete: 0, complete: 1 }

  has_many :comments, :dependent => :delete_all

  has_many :likes, :dependent => :delete_all


  def get_viewers_ids

    self.viewers_ids.map(&:to_i)

  end


  def author_username

    self.profile.user.username

  end

  def author_profile_picture

    self.profile.profile_picture.url

  end

  def author_user_type

    self.profile.user.user_type

  end

  def get_attributes

    attributes = {}

    attributes[:id] = self.id

    attributes[:profile_id] = self.profile_id

    attributes[:caption] = self.caption

    attributes[:product_id] = self.product_id

    attributes[:media_type] = self.media_type

    attributes[:created_at] = self.created_at

    attributes[:updated_at] = self.updated_at

    attributes[:image_file] = self.image_file

    attributes[:video_file] = self.video_file

    attributes[:status] = self.status

    attributes[:video_thumbnail] = self.video_thumbnail

    attributes[:is_story] = self.is_story

    attributes[:viewers_ids] = self.get_viewers_ids

    attributes[:author] = {
        username: self.author_username,
        profile_picture: self.author_profile_picture,
        user_type: self.author_user_type
    }


    likes = []


    if self.product_id != nil

      product = Product.find_by(id: self.product_id)



      attributes[:product] = {
          name: product.name,
          picture: product.main_picture.url,
          product_available: product.product_available,
          in_stock: product.stock_quantity != 0,
          store_country: product.store_country,
          id: product.id
      }



    end


    self.likes.each do |like|

      liker = User.find_by(id: like.liker_id)

      liker_username = liker.username

      liker_profile_picture = liker.profile.profile_picture.url

      likes.push({
                     post_id: like.post_id,
                     liker_id: like.liker_id,
                     created_at: like.created_at,
                     updated_at: like.updated_at,
                     liker_username: liker_username,
                     liker_profile_picture: liker_profile_picture,
                     liker_profile_id: liker.profile.id
                 })

    end

    comments = []

    self.comments.order(created_at: :desc).each do |comment|

      author = User.find_by(id: comment.author_id)

      author_username = author.username

      author_profile_picture = author.profile.profile_picture.url


      comments.push({
                        post_id: comment.post_id,
                        author_id: comment.author_id,
                        text: comment.text,
                        created_at: comment.created_at,
                        updated_at: comment.updated_at,
                        author_username: author_username,
                        author_profile_picture: author_profile_picture,
                        id: comment.id,
                        author_profile_id: author.profile.id
                    })

    end

    attributes[:likes] = likes

    attributes[:comments] = comments

    attributes

  end


end
