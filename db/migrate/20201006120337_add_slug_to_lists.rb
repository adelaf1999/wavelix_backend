class AddSlugToLists < ActiveRecord::Migration[6.0]
  def change
    add_column :list, :slug, :string
    add_index :lists, :slug, unique: true
  end
end
