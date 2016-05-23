class AddBotDmChanIdToMembers < ActiveRecord::Migration
  def change
    add_column :members, :bot_dm_channel_id, :string
  end
end
