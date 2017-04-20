class AddArchivedToListItemsDropFromChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :archived
    add_column :list_items, :archived, :boolean, default: false
  end
end
