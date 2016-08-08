class AddReinstalledAtToChannels < ActiveRecord::Migration
  def change
    add_column :channels, :reinstalled_at, :datetime
  end
end
