class RemoveMediaFileFromPosts < ActiveRecord::Migration[6.0]
  def change
    remove_column :posts, :media_file
    add_column :posts, :image_file, :text
    add_column :posts, :video_file, :text
  end
end
