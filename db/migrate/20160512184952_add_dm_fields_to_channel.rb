class AddDmFieldsToChannel < ActiveRecord::Migration
  def change
    add_column :channels, :is_im_channel, :boolean, default: false
    add_column :channels, :dm_user_id, :string
  end
end
