class AddBotInfoToRegisteredTeams < ActiveRecord::Migration
  def change
    remove_column :registered_teams, :auth_token
    add_column :registered_teams, :url, :string
    add_column :registered_teams, :slack_team_id, :string
    add_column :registered_teams, :api_token, :string
    add_column :registered_teams, :bot_user_id, :string
    add_column :registered_teams, :bot_access_token, :string
  end
end
