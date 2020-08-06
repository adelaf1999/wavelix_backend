class CreateEarningAccounts < ActiveRecord::Migration[6.0]
  def change
    create_table :earning_accounts do |t|
      t.decimal :balance, default: 0.0
      t.string :currency, unique: true, null: false
      t.timestamps
    end
  end
end
