class AddFieldsToInstallation < ActiveRecord::Migration
  def change
    add_column :installations, :slack_user_id, :string
    add_column :installations, :slack_team_id, :string
    add_column :installations, :slack_user_api_token, :string
    add_column :installations, :bot_api_token, :string
    add_column :installations, :bot_user_id, :string
    add_column :installations, :last_activity_type, :string
    add_column :installations, :last_activity_date, :datetime
    add_column :installations, :rtm_start_json, :jsonb
    add_column :installations, :auth_json, :jsonb
    add_column :installations, :auth_params_json, :jsonb
  end
end
