class CreateStoreUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :store_users do |t|
      t.string :store_owner_full_name, :null => false
      t.string :store_owner_work_number, :null => false
      t.string :store_name, :null => false
      t.string :store_address, :null => false
      t.string :store_number , :null => false
      t.string :store_country, :null => false
      t.text :store_business_license, :null => false
      t.timestamps
    end
  end
end
