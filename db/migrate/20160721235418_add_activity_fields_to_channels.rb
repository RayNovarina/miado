class AddActivityFieldsToChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :taskbot_msg_from_slack_id
    remove_column :channels, :archived
    remove_column :channels, :deleted
    add_column :channels, :taskbot_msg_to_slack_id, :string
    add_column :channels, :last_activity_type, :string
    add_column :channels, :last_activity_date, :datetime
  end
end
