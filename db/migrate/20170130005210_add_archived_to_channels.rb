class AddArchivedToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :archived, :boolean, default: false
  end
end
