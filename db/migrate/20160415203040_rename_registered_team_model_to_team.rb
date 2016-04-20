class RenameRegisteredTeamModelToTeam < ActiveRecord::Migration
  def change
    rename_table :registered_teams, :teams
  end
end
