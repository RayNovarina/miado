class AddDmFieldsToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :is_dm_channel, :boolean
    add_column :channels, :is_user_dm_channel, :boolean
    add_column :channels, :is_member_dm_channel, :boolean
  end
end
