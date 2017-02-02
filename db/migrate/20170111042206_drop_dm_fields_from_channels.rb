class DropDmFieldsFromChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :is_dm_channel
    remove_column :channels, :is_user_dm_channel
    remove_column :channels, :is_member_dm_channel
  end
end
