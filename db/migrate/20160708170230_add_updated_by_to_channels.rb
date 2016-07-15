class AddUpdatedByToChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :dm_user_id
    remove_column :channels, :bot_dm_channel_id

    add_column :channels, :updated_by_slack_user_id, :string
  end
end
