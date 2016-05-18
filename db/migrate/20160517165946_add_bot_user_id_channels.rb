class AddBotUserIdChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :bot_username

    add_column :channels, :bot_user_id, :string
  end
end
