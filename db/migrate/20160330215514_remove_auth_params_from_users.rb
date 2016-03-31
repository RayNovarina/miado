class RemoveAuthParamsFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :provider
    remove_column :users, :uid
    remove_column :users, :auth_token
    remove_column :users, :auth_params_json
    remove_column :users, :auth_json
  end
end
