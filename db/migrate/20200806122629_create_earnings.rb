class CreateEarnings < ActiveRecord::Migration[6.0]
  def change
    create_table :earnings do |t|
      t.decimal :amount, null: false
      t.string :currency, default: 'USD'
      t.timestamps
    end
  end
end
