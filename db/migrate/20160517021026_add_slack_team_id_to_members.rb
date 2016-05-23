class AddSlackTeamIdToMembers < ActiveRecord::Migration
  def change
    add_column :members, :slack_team_id, :string
  end
end
