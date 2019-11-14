class CreateCustomerUsers < ActiveRecord::Migration[6.0]
  def change

    create_table :customer_users do |t|
      t.string :full_name, :null => false
      t.string :date_of_birth, :null => false
      t.string :residential_address, :null => false
      t.string :gender, :null => false
      t.string :country_of_residence, :null => false
      t.timestamps
    end
  end

end
