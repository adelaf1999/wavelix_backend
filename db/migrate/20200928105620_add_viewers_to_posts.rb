class AddViewersToPosts < ActiveRecord::Migration[6.0]
  def change
    add_column :posts, :viewers_ids, :text, array: true, default: []
  end
end
