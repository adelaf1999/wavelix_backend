class AddTokensToEmployees < ActiveRecord::Migration[6.0]
  def change
    add_column :employees, :tokens, :json
  end
end
