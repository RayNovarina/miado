class AddMembersHashToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :members_hash, :jsonb
    add_column :teams, :slack_user_id, :string
  end
end
