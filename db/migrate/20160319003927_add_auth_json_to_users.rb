class AddAuthJsonToUsers < ActiveRecord::Migration
  def change
    remove_column :users, :auth_info
    add_column :users, :auth_json, :jsonb
  end
end
