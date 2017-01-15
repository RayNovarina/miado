class AddIsDmChanToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :is_dm_channel, :boolean, default: false
  end
end
