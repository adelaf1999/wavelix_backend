class RemoveStatusFromPosts < ActiveRecord::Migration[6.0]
  def change
    remove_column :posts, :status
  end
end
