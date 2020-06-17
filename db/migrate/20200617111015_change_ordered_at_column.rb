class ChangeOrderedAtColumn < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :ordered_at
  end
end
