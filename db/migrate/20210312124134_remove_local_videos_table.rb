class RemoveLocalVideosTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :local_videos
  end
end
