class AddTimezoneToPayments < ActiveRecord::Migration[6.0]

  def change
    add_column :payments, :timezone, :string, null: false
  end

end
