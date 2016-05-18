class AddBotMemberInfoToChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :slack_id
    remove_column :channels, :name

    add_column :channels, :slack_channel_name, :string
    add_column :channels, :slack_channel_id, :string
    add_column :channels, :slack_user_id, :string
    add_column :channels, :slack_team_id, :string
    add_column :channels, :slack_user_api_token, :string
    add_column :channels, :bot_dm_channel_id, :string
    add_column :channels, :bot_api_token, :string
    add_column :channels, :bot_username, :string
    add_column :channels, :members_hash, :jsonb
  end
end
