class StockQuantityRequiredForProducts < ActiveRecord::Migration[6.0]
  def change
    remove_column :products, :stock_quantity
    add_column :products, :stock_quantity, :integer, :null => false
  end
end
