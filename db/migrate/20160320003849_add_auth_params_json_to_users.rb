class AddAuthParamsJsonToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auth_params_json, :jsonb
  end
end
