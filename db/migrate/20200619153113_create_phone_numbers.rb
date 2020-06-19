class CreatePhoneNumbers < ActiveRecord::Migration[6.0]
  def change
    create_table :phone_numbers do |t|
      t.string :number, unique: true, null: false
      t.datetime :next_request_at, null: false
      t.timestamps
    end
  end
end
