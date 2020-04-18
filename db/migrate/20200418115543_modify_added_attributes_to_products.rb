class ModifyAddedAttributesToProducts < ActiveRecord::Migration[6.0]
  def change
    change_column :products, :store_country, :string, null: false
    change_column :products, :currency, :string, null: false
  end
end
