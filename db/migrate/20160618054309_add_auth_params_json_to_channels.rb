class AddAuthParamsJsonToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :auth_params_json, :jsonb
  end
end
