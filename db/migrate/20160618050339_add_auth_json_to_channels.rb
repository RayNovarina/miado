class AddAuthJsonToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :auth_json, :jsonb
  end
end
