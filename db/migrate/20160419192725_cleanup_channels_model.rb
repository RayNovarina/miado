class CleanupChannelsModel < ActiveRecord::Migration
  def change
    remove_column :channels, :member_id

    add_reference :channels, :team, index: true, foreign_key: true
    add_reference :channels, :member, index: true, foreign_key: true
  end
end
