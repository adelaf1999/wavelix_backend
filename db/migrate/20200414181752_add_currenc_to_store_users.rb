class AddCurrencToStoreUsers < ActiveRecord::Migration[6.0]
  def change
    change_column :store_users, :currency, :string, null: false
  end
end
