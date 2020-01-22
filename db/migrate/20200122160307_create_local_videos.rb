class CreateLocalVideos < ActiveRecord::Migration[6.0]
  def change
    create_table :local_videos do |t|
      t.text :video, null: false
      t.timestamps
    end
  end
end
