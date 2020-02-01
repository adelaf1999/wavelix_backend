class AddStatusToFollows < ActiveRecord::Migration[6.0]
  def change
    add_column :follows, :status, :integer, default: 1
  end
end
