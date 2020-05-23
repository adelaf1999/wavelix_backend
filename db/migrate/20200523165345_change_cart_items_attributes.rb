class ChangeCartItemsAttributes < ActiveRecord::Migration[6.0]
  def change
    remove_column :cart_items, :delivery_location
    remove_column :cart_items, :order_type
    add_column :cart_items, :delivery_location, :text
    add_column :cart_items, :order_type, :integer
  end
end
