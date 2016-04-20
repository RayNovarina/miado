class CleanupListItemsModel < ActiveRecord::Migration
  def change
    remove_column :channels, :member_id
  end
end
