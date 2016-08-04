class AddSlackUserNameToMembers < ActiveRecord::Migration
  def change
    remove_column :members, :name
    remove_column :members, :real_name
    remove_column :members, :channel_id
    remove_column :members, :is_bot
    remove_column :members, :deleted
    remove_column :members, :bot_dm_channel_id
    add_column :members, :slack_user_name, :string
    add_column :members, :slack_user_real_name, :string
  end
end
