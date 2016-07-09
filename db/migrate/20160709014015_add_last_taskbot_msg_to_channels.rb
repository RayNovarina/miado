class AddLastTaskbotMsgToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :taskbot_msg_from_slack_id, :string
    add_column :channels, :taskbot_msg_date, :datetime
  end
end
