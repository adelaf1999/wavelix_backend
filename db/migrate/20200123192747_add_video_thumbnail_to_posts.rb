class AddVideoThumbnailToPosts < ActiveRecord::Migration[6.0]

  def change
    add_column :posts, :video_thumbnail, :text
  end

end
