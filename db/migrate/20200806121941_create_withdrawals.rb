class CreateWithdrawals < ActiveRecord::Migration[6.0]
  def change
    create_table :withdrawals do |t|
      t.decimal :amount, null: false
      t.string :currency, null: false
      t.integer :store_user_id
      t.integer :driver_id
      t.timestamps
    end
  end
end
