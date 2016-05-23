class AddDeletedAttribsToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :archived, :boolean, default: false
    add_column :channels, :deleted, :boolean, default: false
  end
end
