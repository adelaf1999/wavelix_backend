class AddPostAuthorIdToPostCases < ActiveRecord::Migration[6.0]
  def change
    add_column :post_cases, :post_author_id, :integer, null: false
  end
end
