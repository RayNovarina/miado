class CleanupMembersModel < ActiveRecord::Migration
  def change
    remove_column :members, :first_name
    remove_column :members, :last_name
    remove_column :members, :real_name_normalized
    remove_column :members, :image_72
    remove_column :members, :registered_team_id
    remove_column :members, :slack_team_id
    
    add_column :members, :real_name, :string
  end
end
