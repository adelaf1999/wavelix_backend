class ModifyLikesColumns < ActiveRecord::Migration[6.0]
  def change
    change_column :likes, :post_id, :integer, null: false
    change_column :likes, :liker_id, :integer, null: false
  end
end
