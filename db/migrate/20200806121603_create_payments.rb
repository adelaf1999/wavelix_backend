class CreatePayments < ActiveRecord::Migration[6.0]
  def change
    create_table :payments do |t|
      t.decimal :amount, null: false
      t.decimal :fee, null: false
      t.decimal :net, null: false
      t.string :currency, null:false
      t.integer :store_user_id, null: false
      t.integer :driver_id, null: false
      t.timestamps
    end
  end
end
