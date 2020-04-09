class AddIsStoryToPosts < ActiveRecord::Migration[6.0]
  def change
    add_column :posts, :is_story, :boolean, default: false
  end
end
