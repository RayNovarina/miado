class AddChannelIdToListItems < ActiveRecord::Migration
  def change
    add_column :list_items, :channel_id, :string
  end
end
