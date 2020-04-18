class AddAttributesToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :store_country, :string
    add_column :products, :currency, :string
  end
end
