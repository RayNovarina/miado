class AddRtmStartJsonToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :rtm_start_json, :jsonb
  end
end
