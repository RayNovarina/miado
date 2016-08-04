class AddBotMsgsToMembers < ActiveRecord::Migration
  def change
    add_column :members, :bot_msgs_json, :jsonb
  end
end
