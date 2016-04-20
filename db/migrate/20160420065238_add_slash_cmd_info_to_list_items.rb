class AddSlashCmdInfoToListItems < ActiveRecord::Migration
  def change
    remove_reference :list_items, :channel

    add_column :list_items, :channel_name, :string
    add_column :list_items, :command_text, :string
    add_column :list_items, :team_domain, :string
    add_column :list_items, :team_id, :string
    add_column :list_items, :slack_user_id, :string
    add_column :list_items, :slack_user_name, :string
    add_column :list_items, :slack_deferred_response_url, :string
  end
end
