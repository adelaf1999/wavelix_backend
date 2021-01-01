class AddPostAuthorUsernameToPostCases < ActiveRecord::Migration[6.0]
  def change
    add_column :post_cases, :post_author_username, :string, null: false
  end
end
