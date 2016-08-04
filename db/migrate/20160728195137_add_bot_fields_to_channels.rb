class AddBotFieldsToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :slack_messages, :jsonb
    add_column :channels, :is_taskbot, :boolean, default: false
  end
end
