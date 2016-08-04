class AddInstallInfoToMembers < ActiveRecord::Migration
  def change
    add_column :members, :slack_team_name, :string
    add_column :members, :slack_user_api_token, :string
    add_column :members, :bot_api_token, :string
    add_column :members, :bot_user_id, :string
    add_column :members, :bot_dm_channel_id, :string
    add_column :members, :last_activity_type, :string
    add_column :members, :last_activity_date, :datetime
  end
end
