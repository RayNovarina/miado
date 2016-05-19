class RemoveIsImChanFromChannels < ActiveRecord::Migration
  def change
    remove_column :channels, :is_im_channel
  end
end
