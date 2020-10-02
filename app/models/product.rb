include OrderHelper # Needs to be included outside class so methods on the class and instance methods can use functions from helper

class Product < ApplicationRecord


  validates_presence_of :name, :price, :main_picture, :category_id

  mount_uploader :main_picture, ImageUploader

  mount_uploaders :product_pictures, ImageUploader

  belongs_to :category

  belongs_to :store_user

  serialize :product_attributes, Hash

  serialize :product_pictures, Array


  before_validation :add_store_attributes, on: :create




  def self.similar_items(product, customer_user)



      items = self.where(stock_quantity: nil).or(where('stock_quantity > ?', 0))
                  .where(product_available: true, store_country: customer_user.country)
                  .where.not(id: product.id)
                  .where("similarity(name, ?) > 0.3 AND similarity(name, ?) < 1", product.name, product.name)
                  .order(Arel.sql("similarity(name, #{ActiveRecord::Base.connection.quote(product.name)}) DESC"))


      items = items.uniq { |item|  item.name }.first(10)


      similar_items = []

      items.each do |item|


        similar_items.push({
                               name: item.name,
                               price: convert_amount(item.price, item.currency, customer_user.default_currency),
                               picture: item.main_picture.url,
                               id: item.id,
                               currency: customer_user.default_currency
                           })

      end

      similar_items





  end



  def remove_image(image_name)

    # image index is the image index in the product_pictures array

    # Remove Image from product pictures

    deleted_image = self.product_pictures.delete_at(find_image_index(self.product_pictures, image_name) || self.product_pictures.length)

    deleted_image.try(:remove!)

    self.save


  end


  def get_images

    images = []

    self.product_pictures.each do |picture|

      images.push({
                      uri: picture.url,
                      image_name: picture.file.filename
                  })

    end

    images


  end

  private

  def add_store_attributes

    store_user = self.category.store_user

    self.currency = store_user.currency

    self.store_country = store_user.store_country

    self.store_user_id = store_user.id

  end



  def find_image_index(images, image_name)

    image_names = []

    images.each do |image|
      image_names.push(image.file.filename)
    end


    image_names.index(image_name)

  end

  def is_positive_integer?(arg)

    res = /^(?<num>\d+)$/.match(arg)

    if res == nil
      false
    else
      true
    end

  end


end
