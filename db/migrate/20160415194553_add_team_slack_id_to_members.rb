class AddTeamSlackIdToMembers < ActiveRecord::Migration
  def change
    add_column :members, :slack_user_id, :string
    add_column :members, :slack_team_id, :string
  end
end
